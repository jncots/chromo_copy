      SUBROUTINE CHEPEVT
C-----------------------------------------------------------------------
C  Convert to HEPEVT common block
C
C-----------------------------------------------------------------------
      IMPLICIT NONE

C The common blocks are copied from coms.f in URQMD       
      integer nmax
      parameter (nmax = 40000)

      integer Ap, At, Zp, Zt, npart, nbar, nmes, ctag
      integer nsteps,ranseed,event,eos,dectag,uid_cnt
      integer NHardRes,NSoftRes,NDecRes,NElColl,NBlColl
      logical success
      common /sys/ npart, nbar, nmes, ctag,nsteps,uid_cnt,
     +             ranseed,event,Ap,At,Zp,Zt,eos,dectag,
     +             NHardRes,NSoftRes,NDecRes,NElColl,NBlColl,
     +             success

      integer spin(nmax),ncoll(nmax),charge(nmax),strid(nmax),
     +        ityp(nmax),lstcoll(nmax),iso3(nmax),origin(nmax),uid(nmax)
      common/isys/spin,ncoll,charge,ityp,lstcoll,iso3,origin,
     +            uid

      real*8  time,  acttime, bdist, ebeam, bimp,bmin,ecm
      common /rsys/ time,acttime,bdist,bimp,bmin,ebeam,ecm

      real*8 
     +     r0(nmax), rx(nmax), ry(nmax), rz(nmax),
     +     p0(nmax), px(nmax), py(nmax), pz(nmax),
     +     fmass(nmax), rww(nmax), 
     +     dectime(nmax), tform(nmax), xtotfac(nmax)
      common /coor/ r0, rx, ry, rz, p0, px, py, pz, fmass, rww, dectime
      
      integer nstable, maxstables
      parameter(maxstables=20)
      integer stabvec(maxstables)
      common /stables/nstable,stabvec
      
      INTEGER NEVHEP,NMXHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      DOUBLE PRECISION PHEP,VHEP
      PARAMETER (NMXHEP=nmax)
      COMMON /HEPEVT/ NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &                JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),
     &                VHEP(4,NMXHEP)
      INTEGER ICHG
      COMMON /UQCHG/  ICHG(NMXHEP)
      
      INTEGER I, PDGID, IPDG, ISTIDX

      DO I=1,npart
C         WRITE(6,*) I, ich(I), esp(:,I)
         NEVHEP = event
         NHEP = NPART
         ISTHEP(I) = 1
c DO ISTIDX=1,NSTABLE
c    IF (ITYP(I).EQ.STABVEC(ISTIDX)) THEN
c       ISTHEP(I) = 1
c    ELSE
c       ISTHEP(I) = 2
c    ENDIF
c ENDDO
         IDHEP(I) = pdgid(ityp(I),iso3(I))
c         WRITE(6,*) I,'/',npart, ityp(I),iso3(I), IDHEP(I)
         PHEP(1,I) = px(I)
         PHEP(2,I) = py(I)
         PHEP(3,I) = pz(I)
         PHEP(4,I) = p0(I)
         PHEP(5,I) = fmass(I)
         VHEP(1,I) = rx(I)
         VHEP(2,I) = ry(I)
         VHEP(3,I) = rz(I)
         VHEP(4,I) = r0(I)
         JMOHEP(1,I) = origin(I)
         ICHG(I) = charge(I)
      END DO

      END