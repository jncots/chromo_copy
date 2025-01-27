C This file are aux functions for stand-alone use
C of CORSIKA interaction models

      SUBROUTINE CQGSINI( DATDIR, LUN, DEBUGNUM )
C-----------------------------------------------------------------------
C  C(ompact) Q(UARK) G(LUON) S(TRING JET MODEL) INI(TIALZATION)
C
C  INITIALIZES QGSJET-II MODEL quitely and fully.
C  THIS SUBROUTINE IS CALLED FROM START.
C-----------------------------------------------------------------------
      IMPLICIT NONE
      CHARACTER DATDIR*(256)
      COMMON /AREA40/  JDIFR
      INTEGER          JDIFR
      INTEGER        VERSION
      INTEGER    LUN, moniou
      INTEGER    DEBUGNUM, debug 
      common /qgarr43/ moniou
      common /qgdebug/ debug
      SAVE
C-----------------------------------------------------------------------

C  COMMON MODEL PARAMETERS SETTING
      CALL QGSET
      moniou = LUN
      debug = DEBUGNUM
C  Call global initialization subroutine
      CALL QGAINI( DATDIR )
C  Call cross-section initialization subroutine
C      CALL QGSSIGINI

      END

      SUBROUTINE CHEPEVT
C-----------------------------------------------------------------------
C  Convert to HEPEVT common block
C
C-----------------------------------------------------------------------
      IMPLICIT NONE

      INTEGER NPTMAX, ICH, NSP
      DOUBLE PRECISION ESP
      PARAMETER(NPTMAX=95000)
      COMMON /QGARR12/ NSP
      COMMON /QGARR14/ ESP(4,NPTMAX),ICH(NPTMAX)


      INTEGER NEVHEP,NMXHEP,NHEP,ISTHEP,IDHEP,JMOHEP,JDAHEP
      DOUBLE PRECISION PHEP,VHEP
      PARAMETER (NMXHEP=NPTMAX)
      COMMON /HEPEVT/ NEVHEP,NHEP,ISTHEP(NMXHEP),IDHEP(NMXHEP),
     &                JMOHEP(2,NMXHEP),JDAHEP(2,NMXHEP),PHEP(5,NMXHEP),
     &                VHEP(4,NMXHEP)
      INTEGER ICHG
      COMMON /QGCHG/  ICHG(NMXHEP)
C     Particle tables start with the ID -10(rho0) going through 0 (pi0).
      character*12 NAME(-10:10)
      DATA NAME /
     &'rho0        ','Lambda_cbar-','Dbar0       ','D-          ',
     &'Lambdabar0  ','K_L0        ','K-          ','nbar0       ',
     &'pbar-       ','pi-         ','pi0         ','pi+         ',
     &'p+          ','n0          ','K+          ','K_S0        ',
     &'Lambda0     ','D+          ','D0          ','Lambda_c+   ',
     &'eta         '/
      
      INTEGER IPDGID(-10:10)
      DATA IPDGID /
     &   113, -4122,  -421,  -411, -3122,   130,  -321, -2112, -2212,
     &  -211,   111,   211,  2212,  2112,   321,   310,  3122,   411,
     &   421,  4122,   221/
      
      DOUBLE PRECISION QMASS(-10:10)
      DATA QMASS /
     &.548d0,2.27d0,1.868d0,1.868d0,1.116d0,.496d0,.496d0,0.93827999,
     &0.93827999,.14d0,.14d0,.14d0,0.93827999,0.93827999,.496d0,.496d0,
     &1.116d0,1.868d0,1.868d0,2.27d0,.548d0/

      INTEGER ICHRG(-10:10)
      DATA ICHRG /
     &     0,    -1,     0,    -1,     0,     0,    -1,     0,
     &    -1,    -1,     0,     1,     1,     0,     1,     0,
     &     0,     1,     0,     1,     0/

      INTEGER I

      NHEP = nsp

      DO I=1,nsp
C         WRITE(6,*) I, ich(I), esp(:,I)
         NHEP = NSP
         ISTHEP(I) = 1
         IDHEP(I) = IPDGID(ich(I))
         PHEP(1,I) = esp(3,I)
         PHEP(2,I) = esp(4,I)
         PHEP(3,I) = esp(2,I)
         PHEP(4,I) = esp(1,I)
         PHEP(5,I) = QMASS(ich(I))
         ICHG(I) = ICHRG(ich(I))
      END DO


      END

*-- Author :    D. HECK IK FZK KARLSRUHE       12/01/1996
C=======================================================================

      BLOCK DATA QGSDAT

C-----------------------------------------------------------------------
C  Q(UARK) G(LUON) S(TRING JET MODEL) DAT(A INITIALIZATION)
C
C  INITIALIZES DATA FOR QGSJET LINK.
C-----------------------------------------------------------------------

      IMPLICIT NONE
      COMMON /CRQGSLIN/ICTABL,IQTABL
      INTEGER          ICTABL(200),IQTABL(-10:10)
      SAVE
C  FOLLOWING NOTATIONS FOR PARTICLES TYPES ARE USED WITHIN QGSJET:
C             0 - PI0,
C             1 - PI+,
C            -1 - PI-,
C             2 - P,
C            -2 - P-BAR,
C             3 - N,
C            -3 - N-BAR,
C             4 - K+,
C            -4 - K-,
C             5 - K0S,
C            -5 - K0L
C             6 - LAMBDA
C            -6 - LAMBDA-BAR
C             7 - D+
C            -7 - D-
C             8 - D0
C            -8 - D0-BAR
C             9 - LAMBDA_C
C            -9 - LAMBDA_C-BAR
C            10 - ETA
C           -10 - RHO0

C  ICTABL CONVERTS CORSIKA PARTICLES INTO QGSJET PARTICLES
C  NO CHARMED PARTICLES POSSIBLE AS PROJECTILES
      DATA ICTABL/
     *   0,   0,   0,   0,   0,   0,   1,   1,  -1,  -5,   ! 10
     *   4,  -4,   3,   2,  -2,   5,  10,   6,   0,   0,   ! 20
     *   0,   0,   0,   0,  -3,  -6,   0,   0,   0,   0,   ! 30
     *   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   ! 40
     *   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   ! 50
     *   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   ! 60
     *   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   ! 70
     *  10,  10,  10,  10,   26*0,
C  CHARMED MESONS
C  CONVERT UNKNOWN CHARMED MESONS TO KNOWN D-MESONS
     *  10*0,                                              !110
     *   0,   0,   0,   0,   0,   8,   7,  -7,  -8,   7,   !120
     *  -7,   0,   8,   7,  -7,  -8,   7,  -7,   0,   0,   !130
C  CHARMED BARYONS
     *   0,   0,   0,   0,   0,   0,   9,   0,   0,   0 ,  !140
     *   0,   0,   0,   0,   0,   0,   0,   0,  -9,   0 ,  !150
     *   50*0 /

C  IQTABL CONVERTS QGSJET PARTICLES INTO CORSIKA PARTICLES
C  INCLUDES CHARMED PARTICLES
C  IQTABL RUNS FROM -10:10
      DATA IQTABL/
     *   51, 149, 119, 118,  26,  10,  12,  25,  15,   9,  ! -10 .... -1
     *   7,                                               !   0
     *   8,  14,  13,  11,  16,  18, 117, 116, 137,  17/  !   1 .... 10

      END

*-- Author :    T. Pierog IKP KIT KARLSRUHE       25/10/2012
C=======================================================================

      subroutine  LzmaOpenFile(name)

C-----------------------------------------------------------------------
C DUMMY FUNCTION TO BE COMPATIBLE WITH CRMC
C-----------------------------------------------------------------------

      IMPLICIT NONE
      character*256 name,name2
      name2=name
      end

*-- Author :    T. Pierog IKP KIT KARLSRUHE       25/10/2012
C=======================================================================

      subroutine  LzmaCloseFile()

C-----------------------------------------------------------------------
C DUMMY FUNCTION TO BE COMPATIBLE WITH CRMC
C-----------------------------------------------------------------------

      IMPLICIT NONE
      end

*-- Author :    T. Pierog IKP KIT KARLSRUHE       25/10/2012
C=======================================================================

      subroutine LzmaFillArray(dum,idum)

C-----------------------------------------------------------------------
C DUMMY FUNCTION TO BE COMPATIBLE WITH CRMC
C-----------------------------------------------------------------------

      IMPLICIT NONE
      double precision dum,dum2
      integer idum,idum2
      dum2=dum
      idum2=idum
      end

*-- Author :    T. Pierog IKP KIT KARLSRUHE       25/10/2012
C=======================================================================

      integer function size(array)

C-----------------------------------------------------------------------
C DUMMY FUNCTION TO BE COMPATIBLE WITH CRMC
C-----------------------------------------------------------------------

      IMPLICIT NONE
      double precision array(*)
      size=int(array(1))
      end