""" This module handles transformations between Lorentz frames and
different inputs required by the low-level event generator interfaces.
"""
import numpy as np
from chromo.util import (
    TaggedFloat,
    energy2momentum,
    momentum2energy,
    elab2ecm,
    ecm2elab,
    mass,
    is_real_nucleus,
    process_particle,
)
from chromo.constants import nucleon_mass, MeV, GeV, TeV, PeV, EeV
from chromo.util import CompositeTarget, EventFrame
from particle import PDGID
import dataclasses
from typing import Union, Tuple


__all__ = (
    "EventFrame",
    "CompositeTarget",
    "MeV",
    "GeV",
    "TeV",
    "PeV",
    "EeV",
    "EventKinematics",
    "CenterOfMass",
    "FixedTarget",
    "TotalEnergy",
    "KinEnergy",
    "Momentum",
)


@dataclasses.dataclass
class EventKinematicsBase:
    """Handles kinematic variables and conversions between reference frames.

    There are different ways to specify a particle collision. For instance
    the projectile and target momenta can be specified in the target rest frame,
    the so called 'laboratory' frame, or the nucleon-nucleon center-of-mass frame
    where the modulus of the nucleon momenta is the same but the direction
    inverted. Each event generator expects its arguments to be given in one
    or the other frame. This class allows the generator to pick itself the correct
    frame, while the user can specify the kinematics in the preferred form.

    Parameters
    ----------
        particle1: str or int or (int, int)
            Particle name, PDG ID, or nucleus mass & charge (A, Z) of projectile.
        particle2: str or int or (int, int) or CompositeTarget
            Particle name, PDG ID, nucleus mass & charge (A, Z), or CompositeTarget
            of the target
        ecm : float, optional
            Center-of-mass energy :math:`\\sqrt{s}`.
        plab : float, optional
            Projectile momentum in lab frame. If the projectile is a nucleus, it is
            the momentum per nucleon.
        elab : float, optional
            Projectile energy in lab frame. If the projectile is a nucleus, it is
            the energy per nucleon.
        ekin : float, optional
            Projectile kinetic energy in lab frame. If the projectile is a nucleus,
            it is the kinetic energy per nucleon.
        beam : tuple of two floats
            Specification as tuple of two momenta. If the projectile or target are
            nuclei, it is the momentum per nucleon.
    """

    frame: EventFrame
    p1: Union[PDGID, Tuple[int, int]]
    p2: Union[PDGID, Tuple[int, int], CompositeTarget]
    ecm: float  # for ions this is nucleon-nucleon collision system
    plab: float
    elab: float
    ekin: float
    beams: Tuple[np.ndarray, np.ndarray]
    _gamma_cm: float
    _betagamma_cm: float

    def apply_boost(self, event, generator_frame):
        if generator_frame == self.frame:
            return
        CMS = EventFrame.CENTER_OF_MASS
        FT = EventFrame.FIXED_TARGET
        if generator_frame == FT and self.frame == CMS:
            bg = -self._betagamma_cm
        elif generator_frame == CMS and self.frame == FT:
            bg = self._betagamma_cm
        else:
            raise NotImplementedError(
                f"Boosts from {generator_frame} to {self.frame} are not yet supported"
            )
        g = self._gamma_cm
        en = g * event.en + bg * event.pz
        pz = bg * event.en + g * event.pz
        event.en[:] = en
        event.pz[:] = pz

    def __eq__(self, other):
        at = dataclasses.astuple(self)
        bt = dataclasses.astuple(other)

        def eq(a, b):
            if isinstance(a, Tuple):
                return all(eq(ai, bi) for (ai, bi) in zip(a, b))
            if isinstance(a, np.ndarray):
                return np.array_equal(a, b)
            return a == b

        return all(eq(a, b) for (a, b) in zip(at, bt))

    def copy(self):
        return EventKinematicsBase(
            self.frame,
            self.p1,
            self.p2.copy() if isinstance(self.p2, CompositeTarget) else self.p2,
            self.ecm,
            self.plab,
            self.elab,
            self.ekin,
            (self.beams[0].copy(), self.beams[1].copy()),
            self._gamma_cm,
            self._betagamma_cm,
        )


class EventKinematics(EventKinematicsBase):
    def __init__(
        self,
        particle1,
        particle2,
        *,
        ecm=None,
        plab=None,
        elab=None,
        ekin=None,
        beam=None,
        frame=None,
    ):
        # Catch input errors

        if sum(x is not None for x in [ecm, plab, elab, ekin, beam]) != 1:
            raise ValueError(
                "Please provide only one of ecm/plab/elab/ekin/beam arguments"
            )

        if particle1 is None or particle2 is None:
            raise ValueError("particle1 and particle2 must be set")

        part1 = process_particle(particle1)
        part2 = process_particle(particle2)

        if isinstance(part1, CompositeTarget):
            raise ValueError("Only 2nd particle can be CompositeTarget")

        p2_is_composite = isinstance(part2, CompositeTarget)

        m1 = nucleon_mass if is_real_nucleus(part1) else mass(part1)
        m2 = nucleon_mass if is_real_nucleus(part2) else mass(part2)

        beams = (np.zeros(4), np.zeros(4))

        # Input specification in center-of-mass frame
        if ecm is not None:
            frame = frame or EventFrame.CENTER_OF_MASS
            ecm = ecm
            elab = ecm2elab(ecm, m1, m2)
            ekin = elab - m1
            plab = energy2momentum(elab, m1)
        # Input specification as 4-vectors
        elif beam is not None:
            if p2_is_composite:
                raise ValueError("beam cannot be used with CompositeTarget")
            frame = frame or EventFrame.GENERIC
            p1, p2 = beam
            beams[0][2] = p1
            beams[1][2] = p2
            beams[0][3] = momentum2energy(p1, m1)
            beams[1][3] = momentum2energy(p2, m2)
            s = np.sum(beams, axis=0)
            # We compute ecm with energy2momentum. It is not really energy to momentum,
            # but energy2momentum(x, y) computes x^2 - y^2, which is what we need. Here,
            # I use that px and py are always zero, if we ever change this, many formulas
            # have to change in this class, like all the boosts
            ecm = energy2momentum(s[3], s[2])
            elab = ecm2elab(ecm, m1, m2)
            ekin = elab - m1
            plab = energy2momentum(elab, m1)
        # Input specification in lab frame
        elif elab is not None:
            if not (elab > m1):
                raise ValueError("projectile energy > projectile mass required")
            frame = frame or EventFrame.FIXED_TARGET
            elab = elab
            ekin = elab - m1
            plab = energy2momentum(elab, m1)
            ecm = elab2ecm(elab, m1, m2)
        elif ekin is not None:
            frame = frame or EventFrame.FIXED_TARGET
            elab = ekin + m1
            plab = energy2momentum(elab, m1)
            ecm = elab2ecm(elab, m1, m2)
        elif plab is not None:
            frame = frame or EventFrame.FIXED_TARGET
            plab = plab
            elab = momentum2energy(plab, m1)
            ekin = elab - m1
            ecm = elab2ecm(elab, m1, m2)
        else:
            assert False  # this should never happen

        # fill beams
        if frame != EventFrame.GENERIC:
            if frame == EventFrame.CENTER_OF_MASS:
                s = ecm**2
                pcm = np.sqrt((s - (m1 + m2) ** 2) * (s - (m1 - m2) ** 2)) / (2 * ecm)
                beams[0][2] = pcm
                beams[1][2] = -pcm
            elif frame == EventFrame.FIXED_TARGET:
                beams[0][2] = plab
                beams[1][2] = 0
            # set energies
            for b, m in zip(beams, (m1, m2)):
                b[3] = np.sqrt(m**2 + b[2] ** 2)

        _gamma_cm = (elab + m2) / ecm
        _betagamma_cm = plab / ecm

        super().__init__(
            frame, part1, part2, ecm, plab, elab, ekin, beams, _gamma_cm, _betagamma_cm
        )


class CenterOfMass(EventKinematics):
    def __init__(self, ecm, particle1, particle2):
        super().__init__(ecm=ecm, particle1=particle1, particle2=particle2)


class TotalEnergy(TaggedFloat):
    pass


class KinEnergy(TaggedFloat):
    pass


class Momentum(TaggedFloat):
    pass


class FixedTarget(EventKinematics):
    def __init__(self, energy, particle1, particle2):
        if isinstance(energy, (TotalEnergy, int, float)):
            super().__init__(
                elab=float(energy), particle1=particle1, particle2=particle2
            )
        elif isinstance(energy, KinEnergy):
            super().__init__(
                ekin=float(energy), particle1=particle1, particle2=particle2
            )
        elif isinstance(energy, Momentum):
            super().__init__(
                plab=float(energy), particle1=particle1, particle2=particle2
            )
        else:
            raise ValueError(
                f"{energy!r} is neither a number nor one of "
                "TotalEnergy, KinEnergy, Momentum"
            )
