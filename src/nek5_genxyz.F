c-----------------------------------------------------------------------
      SUBROUTINE ARCSRF(XML,YML,ZML,NXL,NYL,NZL,IE,ISID)
      INCLUDE 'SIZE'
      INCLUDE 'GEOM'
      INCLUDE 'INPUT'
      INCLUDE 'TOPOL'
      INCLUDE 'WZ'
C
C     ....note..... CTMP1 is used in this format in several subsequent routines
C
      COMMON /CTMP1/ H(LX1,3,2),XCRVED(LX1),YCRVED(LY1),ZCRVED(LZ1)
     $             , ZGML(LX1,3),WORK(3,LX1,LZ1)
      DIMENSION XML(NXL,NYL,NZL,1),YML(NXL,NYL,NZL,1),ZML(NXL,NYL,NZL,1)
      LOGICAL IFGLJ
C
      IFGLJ = .FALSE.
      IF (IFAXIS .AND. IFRZER(IE) .AND. (ISID.EQ.2 .OR. ISID.EQ.4))
     $IFGLJ = .TRUE.
C
      PT1X  = XC(ISID,IE)
      PT1Y  = YC(ISID,IE)
      IF(ISID.EQ.4) THEN
         PT2X = XC(1,IE)
         PT2Y = YC(1,IE)
      ELSE IF(ISID.EQ.8) THEN
         PT2X = XC(5,IE)
         PT2Y = YC(5,IE)
      ELSE
         PT2X = XC(ISID+1,IE)
         PT2Y = YC(ISID+1,IE)
      ENDIF
C
C     Find slope of perpendicular
      RADIUS=CURVE(1,ISID,IE)
      GAP=SQRT( (PT1X-PT2X)**2 + (PT1Y-PT2Y)**2 )
      IF (ABS(2.0*RADIUS).LE.GAP*1.00001) THEN
         WRITE(6,10) RADIUS,ISID,IE,GAP
   10    FORMAT(//,2X,'ERROR: Too small a radius (',G11.3
     $  ,') specified for side',I2,' of element',I4,':  '
     $  ,G11.3,/,2X,'ABORTING during mesh generation.')
         call exitt(1)
      ENDIF
      XS = PT2Y-PT1Y
      YS = PT1X-PT2X
C     Make length Radius
      XYS=SQRT(XS**2+YS**2)
C     Find Center
      DTHETA = ABS(ASIN(0.5*GAP/RADIUS))
      PT12X  = (PT1X + PT2X)/2.0
      PT12Y  = (PT1Y + PT2Y)/2.0
      XCENN  = PT12X - XS/XYS * RADIUS*COS(DTHETA)
      YCENN  = PT12Y - YS/XYS * RADIUS*COS(DTHETA)
      THETA0 = ATAN2((PT12Y-YCENN),(PT12X-XCENN))
      IF (IFGLJ) THEN
         FAC    = SIGN(1.0,RADIUS)
         THETA1 = THETA0 - FAC*DTHETA
         THETA2 = THETA0 + FAC*DTHETA
      ENDIF
C     Compute perturbation of geometry
      ISID1 = MOD1(ISID,4)
      IF (IFGLJ) THEN
         I1 = ISID/2
         I2 = 2 - ISID/4
         DO 15 IY=1,NYL
           ANG  = H(IY,2,I1)*THETA1 + H(IY,2,I2)*THETA2
           XCRVED(IY)=XCENN + ABS(RADIUS)*COS(ANG)
     $                      - (H(IY,2,I1)*PT1X + H(IY,2,I2)*PT2X)
           YCRVED(IY)=YCENN + ABS(RADIUS) * SIN(ANG)
     $                      - (H(IY,2,I1)*PT1Y + H(IY,2,I2)*PT2Y)
   15    CONTINUE
      ELSE
         DO 20 IX=1,NXL
            IXT=IX
            IF (ISID1.GT.2) IXT=NXL+1-IX
            R=ZGML(IX,1)
            IF (RADIUS.LT.0.0) R=-R
            XCRVED(IXT) = XCENN + ABS(RADIUS) * COS(THETA0 + R*DTHETA)
     $                          - ( H(IX,1,1)*PT1X + H(IX,1,2)*PT2X )
            YCRVED(IXT) = YCENN + ABS(RADIUS) * SIN(THETA0 + R*DTHETA)
     $                          - ( H(IX,1,1)*PT1Y + H(IX,1,2)*PT2Y )
   20    CONTINUE
      ENDIF
C     Points all set, add perturbation to current mesh.
      ISID1 = MOD1(ISID,4)
      ISID1 = EFACE1(ISID1)
      IZT = (ISID-1)/4+1
      IYT = ISID1-2
      IXT = ISID1
      IF (ISID1.LE.2) THEN
         CALL ADDTNSR(XML(1,1,1,IE),H(1,1,IXT),XCRVED,H(1,3,IZT)
     $               ,NXL,NYL,NZL)
         CALL ADDTNSR(YML(1,1,1,IE),H(1,1,IXT),YCRVED,H(1,3,IZT)
     $               ,NXL,NYL,NZL)
      ELSE
         CALL ADDTNSR(XML(1,1,1,IE),XCRVED,H(1,2,IYT),H(1,3,IZT)
     $               ,NXL,NYL,NZL)
         CALL ADDTNSR(YML(1,1,1,IE),YCRVED,H(1,2,IYT),H(1,3,IZT)
     $               ,NXL,NYL,NZL)
      ENDIF
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE DEFSRF(XML,YML,ZML,NXL,NYL,NZL,IE,IFACE1,CCV)
      INCLUDE 'SIZE'
      INCLUDE 'TOPOL'
      INCLUDE 'GEOM'
      INCLUDE 'WZ'
      COMMON /CTMP1/ H(LX1,3,2),XCRVED(LX1),YCRVED(LY1),ZCRVED(LZ1)
     $             , ZGML(LX1,3),WORK(3,LX1,LZ1)
C
      DIMENSION XML(NXL,NYL,NZL,1),YML(NXL,NYL,NZL,1),ZML(NXL,NYL,NZL,1)
      DIMENSION X1(3),X2(3),X3(3),DX(3)
      DIMENSION IOPP(3),NXX(3)
      CHARACTER*1 CCV
C
      CALL DSSET(NXL,NYL,NZL)
      IFACE  = EFACE1(IFACE1)
      JS1    = SKPDAT(1,IFACE)
      JF1    = SKPDAT(2,IFACE)
      JSKIP1 = SKPDAT(3,IFACE)
      JS2    = SKPDAT(4,IFACE)
      JF2    = SKPDAT(5,IFACE)
      JSKIP2 = SKPDAT(6,IFACE)
C
      IOPP(1) = NXL-1
      IOPP(2) = NXL*(NYL-1)
      IOPP(3) = NXL*NYL*(NZL-1)
      NXX(1)  = NXL
      NXX(2)  = NYL
      NXX(3)  = NZL
      IDIR    = 2*MOD(IFACE,2) - 1
      IFC2    = (IFACE+1)/2
      DELT    = 0.0
C      DELT    = SIDE(4,IFACE,IE)
C
C     Compute surface deflection and perturbation due to face IFACE
C
      DO 200 J2=JS2,JF2,JSKIP2
      DO 200 J1=JS1,JF1,JSKIP1
         JOPP = J1 + IOPP(IFC2)*IDIR
         X2(1) = XML(J1,J2,1,IE)
         X2(2) = YML(J1,J2,1,IE)
         X2(3) = ZML(J1,J2,1,IE)
         X1(1) = XML(JOPP,J2,1,IE)
         X1(2) = YML(JOPP,J2,1,IE)
         X1(3) = ZML(JOPP,J2,1,IE)
         CALL INTRSC(X3,X2,X1,DELT,IE,IFACE1)
C
         DX(1) = X3(1)-X2(1)
         DX(2) = X3(2)-X2(2)
         DX(3) = X3(3)-X2(3)
C
         NXS = NXX(IFC2)
         JOFF = (J1-JOPP)/(NXS-1)
         DO 100 IX = 2,NXS
            J = JOPP + JOFF*(IX-1)
            ZETA = 0.5*(ZGML(IX,IFC2) + 1.0)
            XML(J,J2,1,IE) = XML(J,J2,1,IE)+DX(1)*ZETA
            YML(J,J2,1,IE) = YML(J,J2,1,IE)+DX(2)*ZETA
            ZML(J,J2,1,IE) = ZML(J,J2,1,IE)+DX(3)*ZETA
  100    CONTINUE
  200 CONTINUE
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE INTRSC(X3,X2,X1,DELT,IE,IFACE)
C
      DIMENSION X1(3),X2(3),X3(3)
      COMMON /SRFCEI/ IEL,IFCE
      COMMON /SRFCER/ X0(3),DX(3)
      COMMON /SRFCEL/ SUCCES
      LOGICAL SUCCES
      COMMON /TOLRNC/ TOL
C
C     Load parameters for surface function FNC
C
      IEL   = IE
      IFCE  = IFACE
      X0(1) = X1(1)
      X0(2) = X1(2)
      X0(3) = X1(3)
      DX(1) = X2(1)-X1(1)
      DX(2) = X2(2)-X1(2)
      DX(3) = X2(3)-X1(3)
      DIST  = SQRT ( DX(1)**2 + DX(2)**2 + DX(3)**2 )
C
C     Initial guess for bracket is given by size of element face (DELT).
C
      ETA2  = 1.0
      ETA1  = ETA2 - DELT/DIST
      ETA1  = MAX(ETA1,0.0)
      CALL ZBRAC(ETA1,ETA2,SUCCES)
C
      TOL    = 1.0E-5
      TOLSRF = TOL*(ETA2-ETA1)
      IF (SUCCES) ETA3 = ZBRENT(ETA1,ETA2,TOLSRF)
C
      X3(1) = X0(1) + DX(1)*ETA3
      X3(2) = X0(2) + DX(2)*ETA3
      X3(3) = X0(3) + DX(3)*ETA3
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE ZBRAC(X1,X2,SUCCES)
C
C     Given a function FNC and an initial guess (X1,X2), the routine
C     expands the range geometrically until a root is bracketed by the
C     returned range (X1,X2) [SUCCES=.TRUE.], or until the range becomes
C     unacceptably large [SUCCES=.FALSE.].
C     ( Numerical Recipes, p. 245; pff 9 Aug 1989 09:00:20 )
C
      PARAMETER (FACTOR=1.08,NTRY=50)
      LOGICAL SUCCES
C
      SUCCES = .TRUE.
C
      IF (X1.EQ.X2)  X1 = .99*X1
      IF (X1.EQ.0.0) X1 = 1.0E-04
C
      F1 = FNC(X1)
      F2 = FNC(X2)
      DO 100 J=1,NTRY
         IF (F1*F2.LT.0.0) RETURN
         IF (ABS(F1).LT.ABS(F2)) THEN
            X1 = X1 + FACTOR*(X1-X2)
            F1 = FNC(X1)
         ELSE
            X2 = X2 + FACTOR*(X2-X1)
            F2 = FNC(X2)
         ENDIF
  100 CONTINUE
      SUCCES = .FALSE.
      RETURN
      END
      FUNCTION ZBRENT(X1,X2,TOL)
C
C     Using the Van Wijngaarden-Dekker-Brent Method, find the root
C     of a function FNC known to lie between X1 and X2.  The root,
C     returned as ZBRENT, will be refined until its accuracy is TOL.
C
      PARAMETER (ITMAX=100,EPS=3.0E-8)
C
      A = X1
      B = X2
      FA = FNC(A)
      FB = FNC(B)
      IF (FB*FA.GT.0.0) GOTO 9000
      FC=FB
C
      DO 1000 ITER=1,ITMAX
         IF (FB*FC.GT.0.0) THEN
            C  = A
            FC = FA
            D  = B-A
            E  = D
         ENDIF
         IF (ABS(FC).LT.ABS(FB)) THEN
            A = B
            B = C
            C = A
            FA = FB
            FB = FC
            FC = FA
         ENDIF
         TOL1 = 2.0*EPS*ABS(B)+0.5*TOL
         XM = 0.5*(C-B)
         IF (ABS(XM).LE.TOL1.OR.FB.EQ.0.0) THEN
            ZBRENT = B
            RETURN
         ENDIF
         IF (ABS(E).GT.TOL1.AND. ABS(FA).GT.ABS(FB)) THEN
C
C           Attempt inverse quadratic interpolation
C
            S=FB/FA
            IF (A.EQ.C) THEN
               P=2.0*XM*S
               Q=1.0-S
            ELSE
               Q=FA/FC
               R=FB/FC
               P=S*( 2.0*XM*Q*(Q-R) - (B-A)*(R-1.0) )
               Q=(Q-1.0)*(R-1.0)*(S-1.0)
            ENDIF
C
C           Check whether in bounds...
C
            IF (P.GT.0.0) Q = -Q
            P = ABS(P)
            IF (2.0*P.LT.MIN(3.0*XM*Q-ABS(TOL1*Q),ABS(E*Q))) THEN
C              Accept interpolation.
               E=D
               D=P/Q
            ELSE
C              Interpolation failed, use bisection.
               D=XM
               E=D
            ENDIF
         ELSE
C           Bounds decreasing too slowly, use bisection.
            D=XM
            E=D
         ENDIF
         A=B
         FA=FB
         IF (ABS(D).GT.TOL1) THEN
C           Evaluate new trial root
            B=B+D
         ELSE
            B=B+SIGN(TOL1,XM)
         ENDIF
         FB=FNC(B)
 1000 CONTINUE
C
C
 9000 CONTINUE
      WRITE(6 ,*) 'Exceeding maximum number of iterations.'
C      WRITE(21,*) 'Exceeding maximum number of iterations.'
      ZBRENT=B
      RETURN
      END
      FUNCTION FNC(ETA)
      INCLUDE 'SIZE'
      INCLUDE 'INPUT'
      COMMON /SRFCEI/ IEL,IFCE
      COMMON /SRFCER/ X0(3),DX(3)
      COMMON /SRFCEL/ SUCCES
      DIMENSION X3(3)
      integer icalld
      save    icalld
      data    icalld /0/
C
      IF (CCURVE(IFCE,IEL).EQ.'s') THEN
        xctr   = CURVE(1,IFCE,IEL)
        yctr   = CURVE(2,IFCE,IEL)
        zctr   = CURVE(3,IFCE,IEL)
        RADIUS = CURVE(4,IFCE,IEL)
        X = X0(1) + DX(1)*ETA - XCTR
        Y = X0(2) + DX(2)*ETA - YCTR
        Z = X0(3) + DX(3)*ETA - ZCTR
C
        FNC    = (RADIUS**2 - (X**2+Y**2+Z**2))/(RADIUS**2)
C
      ENDIF
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE SETDEF
C-------------------------------------------------------------------
C
C     Set up deformed element logical switches
C
C-------------------------------------------------------------------
      INCLUDE 'SIZE'
      INCLUDE 'INPUT'
      DIMENSION XCC(8),YCC(8),ZCC(8)
      DIMENSION INDX(8)
      REAL VEC(3,12)
      LOGICAL IFVCHK
C
      COMMON /FASTMD/ IFDFRM(LELT), IFFAST(LELT), IFH2, IFSOLV
      LOGICAL IFDFRM, IFFAST, IFH2, IFSOLV
C
C   Corner notation:
C
C                  4+-----+3    ^ Y
C                  /     /|     |
C                 /     / |     |
C               8+-----+7 +2    +----> X
C                |     | /     /
C                |     |/     /
C               5+-----+6    Z
C
C
      DO 10 IE=1,NELT
         IFDFRM(IE)=.TRUE.
   10 CONTINUE
C
      IF (IFMVBD) RETURN
c
c     Force IFDFRM=.true. for all elements (for timing purposes only)
c
      IF (param(31).ne.0.and.nid.eq.0)
     $   write(6,*) 'NOTE: All elements deformed , param(31) ^=0'
      IF (param(31).ne.0) RETURN
C
C     Check against cases which won't allow for savings in HMHOLTZ
C
      INDX(1)=1
      INDX(2)=2
      INDX(3)=4
      INDX(4)=3
      INDX(5)=5
      INDX(6)=6
      INDX(7)=8
      INDX(8)=7
C
C     Check for deformation (rotation is acceptable).
C
      DO 500 IE=1,NELT
C
      call rzero(vec,36)
      IF (ldim.eq.3) THEN
         DO 100 IEDG=1,8
            IF(CCURVE(IEDG,IE).NE.' ') THEN
               IFDFRM(IE)=.TRUE.
               GOTO 500
            ENDIF
  100    CONTINUE
C
         DO 105 I=1,8
            XCC(I)=XC(INDX(I),IE)
            YCC(I)=YC(INDX(I),IE)
            ZCC(I)=ZC(INDX(I),IE)
  105    CONTINUE
C
         DO 110 I=1,4
            VEC(1,I)=XCC(2*I)-XCC(2*I-1)
            VEC(2,I)=YCC(2*I)-YCC(2*I-1)
            VEC(3,I)=ZCC(2*I)-ZCC(2*I-1)
  110    CONTINUE
C
         I1=4
         DO 120 I=0,1
         DO 120 J=0,1
            I1=I1+1
            I2=4*I+J+3
            VEC(1,I1)=XCC(I2)-XCC(I2-2)
            VEC(2,I1)=YCC(I2)-YCC(I2-2)
            VEC(3,I1)=ZCC(I2)-ZCC(I2-2)
  120    CONTINUE
C
         I1=8
         DO 130 I=5,8
            I1=I1+1
            VEC(1,I1)=XCC(I)-XCC(I-4)
            VEC(2,I1)=YCC(I)-YCC(I-4)
            VEC(3,I1)=ZCC(I)-ZCC(I-4)
  130    CONTINUE
C
         DO 140 I=1,12
            VECLEN = VEC(1,I)**2 + VEC(2,I)**2 + VEC(3,I)**2
            VECLEN = SQRT(VECLEN)
            VEC(1,I)=VEC(1,I)/VECLEN
            VEC(2,I)=VEC(2,I)/VECLEN
            VEC(3,I)=VEC(3,I)/VECLEN
  140    CONTINUE
C
C        Check the dot product of the adjacent edges to see that it is zero.
C
         IFDFRM(IE)=.FALSE.
         IF (  IFVCHK(VEC,1,5, 9)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,1,6,10)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,2,5,11)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,2,6,12)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,3,7, 9)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,3,8,10)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,4,7,11)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,4,8,12)  ) IFDFRM(IE)=.TRUE.
C
C      Check the 2D case....
C
       ELSE
C
         DO 200 IEDG=1,4
            IF(CCURVE(IEDG,IE).NE.' ') THEN
               IFDFRM(IE)=.TRUE.
               GOTO 500
            ENDIF
  200    CONTINUE
C
         DO 205 I=1,4
            XCC(I)=XC(INDX(I),IE)
            YCC(I)=YC(INDX(I),IE)
  205    CONTINUE
C
         VEC(1,1)=XCC(2)-XCC(1)
         VEC(1,2)=XCC(4)-XCC(3)
         VEC(1,3)=XCC(3)-XCC(1)
         VEC(1,4)=XCC(4)-XCC(2)
         VEC(1,5)=0.0
         VEC(2,1)=YCC(2)-YCC(1)
         VEC(2,2)=YCC(4)-YCC(3)
         VEC(2,3)=YCC(3)-YCC(1)
         VEC(2,4)=YCC(4)-YCC(2)
         VEC(2,5)=0.0
C
         DO 220 I=1,4
            VECLEN = VEC(1,I)**2 + VEC(2,I)**2
            VECLEN = SQRT(VECLEN)
            VEC(1,I)=VEC(1,I)/VECLEN
            VEC(2,I)=VEC(2,I)/VECLEN
  220    CONTINUE
C
C        Check the dot product of the adjacent edges to see that it is zero.
C
         IFDFRM(IE)=.FALSE.
         IF (  IFVCHK(VEC,1,3,5)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,1,4,5)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,2,3,5)  ) IFDFRM(IE)=.TRUE.
         IF (  IFVCHK(VEC,2,4,5)  ) IFDFRM(IE)=.TRUE.
       ENDIF
  500 CONTINUE

c     DO IE=1,NELT
c        write(6,*) 'VVV:: IFDFRM(IE)',IE,IFDFRM(IE)
c     ENDDO

      RETURN
      END
      LOGICAL FUNCTION IFVCHK(VEC,I1,I2,I3)
C
C     Take the dot product of the three components of VEC to see if it's zero.
C
      DIMENSION VEC(3,12)
      LOGICAL IFTMP
C
      IFTMP=.FALSE.
      EPSM=1.0E-06
C
      DOT1=VEC(1,I1)*VEC(1,I2)+VEC(2,I1)*VEC(2,I2)+VEC(3,I1)*VEC(3,I2)
      DOT2=VEC(1,I2)*VEC(1,I3)+VEC(2,I2)*VEC(2,I3)+VEC(3,I2)*VEC(3,I3)
      DOT3=VEC(1,I1)*VEC(1,I3)+VEC(2,I1)*VEC(2,I3)+VEC(3,I1)*VEC(3,I3)
C
      DOT1=ABS(DOT1)
      DOT2=ABS(DOT2)
      DOT3=ABS(DOT3)
      DOT=DOT1+DOT2+DOT3
      IF (DOT.GT.EPSM) IFTMP=.TRUE.
C
      IFVCHK=IFTMP
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE GENCOOR (XM3,YM3,ZM3)
C-----------------------------------------------------------------------
C
C     Generate xyz coordinates  for all elements.
C        Velocity formulation : mesh 3 is used
C        Stress   formulation : mesh 1 is used
C
C-----------------------------------------------------------------------
      INCLUDE 'SIZE'
      INCLUDE 'GEOM'
      INCLUDE 'INPUT'
      DIMENSION XM3(LX3,LY3,LZ3,1),YM3(LX3,LY3,LZ3,1),ZM3(LX3,LY3,LZ3,1)
C
C     Select appropriate mesh
C
      IF ( IFGMSH3 ) THEN
         CALL GENXYZ (XM3,YM3,ZM3,NX3,NY3,NZ3)
      ELSE
         CALL GENXYZ (XM1,YM1,ZM1,NX1,NY1,NZ1)
      ENDIF
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE GENXYZ (XML,YML,ZML,NXL,NYL,NZL)
C
      INCLUDE 'SIZE'
      INCLUDE 'WZ'
      INCLUDE 'GEOM'
      INCLUDE 'TOPOL'
      INCLUDE 'INPUT'
      INCLUDE 'PARALLEL'
C
C     Note : CTMP1 is used in this format in several subsequent routines
C
      COMMON /CTMP1/ H(LX1,3,2),XCRVED(LX1),YCRVED(LY1),ZCRVED(LZ1)
     $             , ZGML(LX1,3),WORK(3,LX1,LZ1)
C
      DIMENSION XML(NXL,NYL,NZL,1),YML(NXL,NYL,NZL,1),ZML(NXL,NYL,NZL,1)
      DIMENSION XCB(2,2,2),YCB(2,2,2),ZCB(2,2,2)
C
      CHARACTER*1 CCV
C
C     Initialize geometry arrays
C
      NTOTL = NELT*NXL*NYL*NZL
      CALL RZERO(XML,NTOTL)
      CALL RZERO(YML,NTOTL)
      CALL RZERO(ZML,NTOTL)
C
C   Preprocessor Corner notation:      Symmetric Corner notation:
C
C           4+-----+3    ^ s                    3+-----+4    ^ s
C           /     /|     |                      /     /|     |
C          /     / |     |                     /     / |     |
C        8+-----+7 +2    +----> r            7+-----+8 +2    +----> r
C         |     | /     /                     |     | /     /
C         |     |/     /                      |     |/     /
C        5+-----+6    t                      5+-----+6    t
C
      INDX(1)=1
      INDX(2)=2
      INDX(3)=4
      INDX(4)=3
      INDX(5)=5
      INDX(6)=6
      INDX(7)=8
      INDX(8)=7
      NDIM2 = 2**NDIM
C
C     Loop over all elements:
C
      DO 6000 IE=1,NELT
C
      CALL SETZGML (ZGML,IE,NXL,NYL,NZL,IFAXIS)
C
      DO 10 IX=1,NXL
         H(IX,1,1)=(1.0-ZGML(IX,1))*0.5
         H(IX,1,2)=(1.0+ZGML(IX,1))*0.5
   10 CONTINUE
      DO 20 IY=1,NYL
         H(IY,2,1)=(1.0-ZGML(IY,2))*0.5
         H(IY,2,2)=(1.0+ZGML(IY,2))*0.5
   20 CONTINUE
      IF (ldim.eq.3) THEN
         DO 30 IZ=1,NZL
            H(IZ,3,1)=(1.0-ZGML(IZ,3))*0.5
            H(IZ,3,2)=(1.0+ZGML(IZ,3))*0.5
   30    CONTINUE
      ELSE
         CALL RONE(H(1,3,1),NZL)
         CALL RONE(H(1,3,2),NZL)
      ENDIF
C
      DO 50 IX=1,NDIM2
         I=INDX(IX)
         XCB(IX,1,1)=XC(I,IE)
         YCB(IX,1,1)=YC(I,IE)
         ZCB(IX,1,1)=ZC(I,IE)
   50 CONTINUE
C
C     Map R-S-T space into physical X-Y-Z space.
C
      IZTMAX = NDIM-1
      DO 200 IZT=1,IZTMAX
      DO 200 IYT=1,2
      DO 200 IXT=1,2
C
      DO 200 IZ=1,NZL
      DO 200 IY=1,NYL
         HH = H(IY,2,IYT)*H(IZ,3,IZT)
         DO 100 IX=1,NXL
            HHH = H(IX,1,IXT)*HH
            XML(IX,IY,IZ,IE)=XML(IX,IY,IZ,IE)+HHH*XCB(IXT,IYT,IZT)
            YML(IX,IY,IZ,IE)=YML(IX,IY,IZ,IE)+HHH*YCB(IXT,IYT,IZT)
            ZML(IX,IY,IZ,IE)=ZML(IX,IY,IZ,IE)+HHH*ZCB(IXT,IYT,IZT)
  100    CONTINUE
  200 CONTINUE
C
C     Deform surfaces - general 3D deformations
C                     - extruded geometry deformations
C
      NFACES = 2*NDIM
      DO 1000 IFACE=1,NFACES
        CCV = CCURVE(IFACE,IE)
        IF (CCV.EQ.'s')
     $     CALL SPHSRF(XML,YML,ZML,IFACE,IE,NXL,NYL,NZL,WORK)
        IF (CCV.EQ.'e')
     $     CALL gensrf(XML,YML,ZML,IFACE,IE,NXL,NYL,NZL,ZGML)
 1000 CONTINUE
C
      DO 2000 ISID=1,8
        CCV = CCURVE(ISID,IE)
        IF (CCV.EQ.'C')
     $  CALL ARCSRF(XML,YML,ZML,NXL,NYL,NZL,IE,ISID)
C        IF (CCV.EQ.'W')
 2000 CONTINUE
C
C
 6000 CONTINUE
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE SETZGML (ZGML,IEL,NXL,NYL,NZL,IFAXIS)
C
      INCLUDE 'SIZE'
      INCLUDE 'WZ'
      INCLUDE 'GEOM'
C
      DIMENSION ZGML(LX1,3)
      LOGICAL IFAXIS
C
      CALL RZERO (ZGML,3*NX1)
C
      IF ( IFGMSH3 ) THEN
C
         DO 5 IX=1,NXL
            ZGML(IX,1)=ZGM3(IX,1)
    5    CONTINUE
         IF (IFAXIS .AND. IFRZER(IEL)) THEN
            DO 15 IY=1,NYL
               ZGML(IY,2)=ZAM3(IY)
   15       CONTINUE
         ELSE
            DO 25 IY=1,NYL
               ZGML(IY,2)=ZGM3(IY,2)
   25       CONTINUE
         ENDIF
         DO 35 IZ=1,NZL
            ZGML(IZ,3)=ZGM3(IZ,3)
   35    CONTINUE
C
      ELSE
C
         DO 40 IX=1,NXL
            ZGML(IX,1)=ZGM1(IX,1)
   40    CONTINUE
         IF (IFAXIS .AND. IFRZER(IEL)) THEN
            DO 50 IY=1,NYL
               ZGML(IY,2)=ZAM1(IY)
   50       CONTINUE
         ELSE
            DO 60 IY=1,NYL
               ZGML(IY,2)=ZGM1(IY,2)
   60       CONTINUE
         ENDIF
         DO 70 IZ=1,NZL
            ZGML(IZ,3)=ZGM1(IZ,3)
   70    CONTINUE
C
      ENDIF
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE SPHSRF(XML,YML,ZML,IFCE,IE,NX,NY,NZ,XYSRF)
C
C     5 Aug 1988 19:29:52
C
C     Program to generate spherical shell elements for NEKTON
C     input.  Paul F. Fischer
C
      INCLUDE 'SIZE'
      INCLUDE 'INPUT'
      INCLUDE 'WZ'
      INCLUDE 'TOPOL'
      DIMENSION XML(NX,NY,NZ,1),YML(NX,NY,NZ,1),ZML(NX,NY,NZ,1)
      DIMENSION XYSRF(3,NX,NZ)
C
      COMMON /CTMP1/ H(LX1,3,2),XCRVED(LX1),YCRVED(LY1),ZCRVED(LZ1)
     $             , ZGML(LX1,3),WORK(3,LX1,LZ1)
      COMMON /CTMP0/ XCV(3,2,2),VN1(3),VN2(3)
     $              ,X1(3),X2(3),X3(3),DX(3)
      DIMENSION IOPP(3),NXX(3)
c
c
c     These are representative nodes on a given face, and their opposites
c
      integer cface(2,6)
      save    cface
      data    cface / 1,4 , 2,1 , 3,2 , 4,3 , 1,5 , 5,1 /
      real    vout(3),vsph(3)
      logical ifconcv
c
C
C     Determine geometric parameters
C
      NXM1 = NX-1
      NYM1 = NY-1
      NXY  = NX*NZ
      NXY3 = 3*NX*NZ
      XCTR   = CURVE(1,IFCE,IE)
      YCTR   = CURVE(2,IFCE,IE)
      ZCTR   = CURVE(3,IFCE,IE)
      RADIUS = CURVE(4,IFCE,IE)
      IFACE  = EFACE1(IFCE)
C
C     Generate (normalized) corner vectors XCV(1,i,j):
C
      CALL CRN3D(XCV,XC(1,IE),YC(1,IE),ZC(1,IE),CURVE(1,IFCE,IE),IFACE)
C
C     Generate edge vectors on the sphere RR=1.0,
C     for (r,s) = (-1,*),(1,*),(*,-1),(*,1)
C
      CALL EDG3D(XYSRF,XCV(1,1,1),XCV(1,1,2), 1, 1, 1,NY,NX,NY)
      CALL EDG3D(XYSRF,XCV(1,2,1),XCV(1,2,2),NX,NX, 1,NY,NX,NY)
      CALL EDG3D(XYSRF,XCV(1,1,1),XCV(1,2,1), 1,NX, 1, 1,NX,NY)
      CALL EDG3D(XYSRF,XCV(1,1,2),XCV(1,2,2), 1,NX,NY,NY,NX,NY)
C
C     Generate intersection vectors for (i,j)
C
C     quick check on sign of curvature:        (pff ,  12/08/00)
c
c
      ivtx = cface(1,ifce)
      ivto = cface(2,ifce)
      vout(1) = xc(ivtx,ie)-xc(ivto,ie)
      vout(2) = yc(ivtx,ie)-yc(ivto,ie)
      vout(3) = zc(ivtx,ie)-zc(ivto,ie)
c
      vsph(1) = xc(ivtx,ie)-xctr
      vsph(2) = yc(ivtx,ie)-yctr
      vsph(3) = zc(ivtx,ie)-zctr
      ifconcv = .true.
      sign    = DOT(vsph,vout,3)
      if (sign.gt.0) ifconcv = .false.
c     write(6,*) 'THIS IS SIGN:',sign
c
      DO 200 J=2,NYM1
         CALL CROSS(VN1,XYSRF(1,1,J),XYSRF(1,NX,J))
         DO 200 I=2,NXM1
            CALL CROSS(VN2,XYSRF(1,I,1),XYSRF(1,I,NY))
            if (ifconcv) then
c           IF (IFACE.EQ.1.OR.IFACE.EQ.4.OR.IFACE.EQ.5) THEN
               CALL CROSS(XYSRF(1,I,J),VN2,VN1)
            ELSE
               CALL CROSS(XYSRF(1,I,J),VN1,VN2)
            ENDIF
  200 CONTINUE
C
C     Normalize all vectors to the unit sphere.
C
      DO 300 I=1,NXY
         CALL NORM3D(XYSRF(1,I,1))
  300 CONTINUE
C
C     Scale by actual radius
C
      CALL CMULT(XYSRF,RADIUS,NXY3)
C
C     Add back the sphere center offset
C
      DO 400 I=1,NXY
         XYSRF(1,I,1)=XYSRF(1,I,1)+XCTR
         XYSRF(2,I,1)=XYSRF(2,I,1)+YCTR
         XYSRF(3,I,1)=XYSRF(3,I,1)+ZCTR
  400 CONTINUE
C
C
C     Transpose data, if necessary
C
      IF (IFACE.EQ.1.OR.IFACE.EQ.4.OR.IFACE.EQ.5) THEN
         DO 500 J=1  ,NY
         DO 500 I=J+1,NX
            TMP=XYSRF(1,I,J)
            XYSRF(1,I,J)=XYSRF(1,J,I)
            XYSRF(1,J,I)=TMP
            TMP=XYSRF(2,I,J)
            XYSRF(2,I,J)=XYSRF(2,J,I)
            XYSRF(2,J,I)=TMP
            TMP=XYSRF(3,I,J)
            XYSRF(3,I,J)=XYSRF(3,J,I)
            XYSRF(3,J,I)=TMP
  500    CONTINUE
      ENDIF
C
C     Compute surface deflection and perturbation due to face IFACE
C
      CALL DSSET(NX,NY,NZ)
      JS1    = SKPDAT(1,IFACE)
      JF1    = SKPDAT(2,IFACE)
      JSKIP1 = SKPDAT(3,IFACE)
      JS2    = SKPDAT(4,IFACE)
      JF2    = SKPDAT(5,IFACE)
      JSKIP2 = SKPDAT(6,IFACE)
C
      IOPP(1) = NX-1
      IOPP(2) = NX*(NY-1)
      IOPP(3) = NX*NY*(NZ-1)
      NXX(1)  = NX
      NXX(2)  = NY
      NXX(3)  = NZ
      IDIR    = 2*MOD(IFACE,2) - 1
      IFC2    = (IFACE+1)/2
      DELT    = 0.0
      I=0
      DO 700 J2=JS2,JF2,JSKIP2
      DO 700 J1=JS1,JF1,JSKIP1
         I=I+1
         JOPP = J1 + IOPP(IFC2)*IDIR
         X2(1) = XML(J1,J2,1,IE)
         X2(2) = YML(J1,J2,1,IE)
         X2(3) = ZML(J1,J2,1,IE)
C
         DX(1) = XYSRF(1,I,1)-X2(1)
         DX(2) = XYSRF(2,I,1)-X2(2)
         DX(3) = XYSRF(3,I,1)-X2(3)
C
         NXS = NXX(IFC2)
         JOFF = (J1-JOPP)/(NXS-1)
         DO 600 IX = 2,NXS
            J = JOPP + JOFF*(IX-1)
            ZETA = 0.5*(ZGML(IX,IFC2) + 1.0)
            XML(J,J2,1,IE) = XML(J,J2,1,IE)+DX(1)*ZETA
            YML(J,J2,1,IE) = YML(J,J2,1,IE)+DX(2)*ZETA
            ZML(J,J2,1,IE) = ZML(J,J2,1,IE)+DX(3)*ZETA
  600    CONTINUE
  700 CONTINUE
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE EDG3D(XYSRF,X1,X2,I1,I2,J1,J2,NX,NY)
C
C     Generate XYZ vector along an edge of a surface.
C
      INCLUDE 'SIZE'
      COMMON /CTMP1/ H(LX1,3,2),XCRVED(LX1),YCRVED(LY1),ZCRVED(LZ1)
     $             , ZGML(LX1,3),WORK(3,LX1,LZ1)
C
      DIMENSION XYSRF(3,NX,NY)
      DIMENSION X1(3),X2(3)
      REAL U1(3),U2(3),VN(3),B(3)
C
C     Normalize incoming vectors
C
      CALL COPY (U1,X1,3)
      CALL COPY (U2,X2,3)
      CALL NORM3D (U1)
      CALL NORM3D (U2)
C
C     Find normal to the plane and tangent to the curve.
C
      CALL CROSS(VN,X1,X2)
      CALL CROSS( B,VN,X1)
      CALL NORM3D (VN)
      CALL NORM3D (B)
C
      CTHETA = DOT(U1,U2,3)
      THETA  = ACOS(CTHETA)
C
      IJ = 0
      DO 200 J=J1,J2
      DO 200 I=I1,I2
         IJ = IJ + 1
         THETAP = 0.5*THETA*(ZGML(IJ,1)+1.0)
         CTP = COS(THETAP)
         STP = SIN(THETAP)
         DO 200 IV = 1,3
            XYSRF(IV,I,J) = CTP*U1(IV) + STP*B(IV)
  200 CONTINUE
      RETURN
      END
      REAL FUNCTION DOT(V1,V2,N)
C
C     Compute Cartesian vector dot product.
C
      DIMENSION V1(N),V2(N)
C
      SUM = 0
      DO 100 I=1,N
         SUM = SUM + V1(I)*V2(I)
  100 CONTINUE
      DOT = SUM
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE CROSS(V1,V2,V3)
C
C     Compute Cartesian vector dot product.
C
      DIMENSION V1(3),V2(3),V3(3)
C
      V1(1) = V2(2)*V3(3) - V2(3)*V3(2)
      V1(2) = V2(3)*V3(1) - V2(1)*V3(3)
      V1(3) = V2(1)*V3(2) - V2(2)*V3(1)
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE NORM3D(V1)
C
C     Compute Cartesian vector dot product.
C
      DIMENSION V1(3)
C
      VLNGTH = DOT(V1,V1,3)
      VLNGTH = SQRT(VLNGTH)
      if (vlngth.gt.0) then
         V1(1) = V1(1) / VLNGTH
         V1(2) = V1(2) / VLNGTH
         V1(3) = V1(3) / VLNGTH
      endif
C
      RETURN
      END
c-----------------------------------------------------------------------
      SUBROUTINE CRN3D(XCV,XC,YC,ZC,CURVE,IFACE)
      INCLUDE 'SIZE'
      INCLUDE 'TOPOL'
      DIMENSION XCV(3,2,2),XC(8),YC(8),ZC(8),CURVE(4)
      DIMENSION INDVTX(4,6)
      SAVE      INDVTX
      DATA      INDVTX  / 1,5,3,7 , 2,4,6,8 , 1,2,5,6
     $                  , 3,7,4,8 , 1,3,2,4 , 5,6,7,8 /
C
      EPS    = 1.0E-5
      XCTR   = CURVE(1)
      YCTR   = CURVE(2)
      ZCTR   = CURVE(3)
      RADIUS = CURVE(4)
C
      DO 10 I=1,4
         J=INDVTX(I,IFACE)
         K=INDX(J)
         XCV(1,I,1)=XC(K)-XCTR
         XCV(2,I,1)=YC(K)-YCTR
         XCV(3,I,1)=ZC(K)-ZCTR
   10 CONTINUE
C
C     Check to ensure that these points are indeed on the sphere.
C
      IF (RADIUS.LE.0.0) THEN
         WRITE(6,20) NID,XCTR,YCTR,ZCTR,IFACE
  20     FORMAT(I5,'ERROR: Sphere of radius zero requested.'
     $       ,/,5X,'EXITING in CRN3D',3E12.4,I3)
         call exitt(1)
      ELSE
         DO 40 I=1,4
            RADT=XCV(1,I,1)**2+XCV(2,I,1)**2+XCV(3,I,1)**2
            RADT=SQRT(RADT)
            TEST=ABS(RADT-RADIUS)/RADIUS
            IF (TEST.GT.EPS) THEN
             WRITE(6,30) NID
     $      ,RADT,RADIUS,XCV(1,I,1),XCV(2,I,1),XCV(3,I,1)
   30        FORMAT(I5,'ERROR: Element vertex not on requested sphere.'
     $           ,/,5X,'EXITING in CRN3D',5E12.4)
             call exitt(1)
            ENDIF
   40    CONTINUE
      ENDIF
C
      RETURN
      END
c-----------------------------------------------------------------------
      subroutine gensrf(XML,YML,ZML,IFCE,IE,MX,MY,MZ,zgml)
C
C     9 Mar 1994
C
C     Program to generate surface deformations for NEKTON
C     input.  Paul F. Fischer
C
c     INCLUDE 'basics.inc'
      INCLUDE 'SIZE'
      INCLUDE 'INPUT'
      INCLUDE 'WZ'
      INCLUDE 'TOPOL'
C
      DIMENSION XML(MX,MY,MZ,1),YML(MX,MY,MZ,1),ZML(MX,MY,MZ,1)
     $             ,ZGML(MX,3)
C
      real IOPP(3),MXX(3),X0(3),DX(3)
C
C
C     Algorithm:  .Project original point onto surface S
C                 .Apply Gordon Hall to vector of points between x_s and
C                  opposite face
C
C
      CALL DSSET(MX,MY,MZ)
C
      IFACE  = EFACE1(IFCE)
c
c     Beware!!  SKPDAT different from preprocessor/postprocessor!
c
      JS1    = SKPDAT(1,IFACE)
      JF1    = SKPDAT(2,IFACE)
      JSKIP1 = SKPDAT(3,IFACE)
      JS2    = SKPDAT(4,IFACE)
      JF2    = SKPDAT(5,IFACE)
      JSKIP2 = SKPDAT(6,IFACE)
c
      IOPP(1) = MX-1
      IOPP(2) = MX*(MY-1)
      IOPP(3) = MX*MY*(MZ-1)
      MXX(1)  = MX
      MXX(2)  = MY
      MXX(3)  = MZ
      IDIR    = 2*MOD(IFACE,2) - 1
      IFC2    = (IFACE+1)/2
      I=0
C
C     Find a characteristic length scale for initializing secant method
C
      x0(1) = xml(js1,js2,1,ie)
      x0(2) = yml(js1,js2,1,ie)
      x0(3) = zml(js1,js2,1,ie)
      rmin  = 1.0e16
c
c
c
      DO 100 J2=JS2,JF2,JSKIP2
      DO 100 J1=JS1,JF1,JSKIP1
         if (j1.ne.js1.or.j2.ne.js2) then
            r2 = (x0(1) - xml(j1,j2,1,ie))**2
     $         + (x0(2) - yml(j1,j2,1,ie))**2
     $         + (x0(3) - zml(j1,j2,1,ie))**2
            rmin = min(r2,rmin)
         endif
  100 CONTINUE
      dxc = 0.05*sqrt(rmin)
C
C     Project each point on this surface onto curved surface
C
      DO 300 J2=JS2,JF2,JSKIP2
      DO 300 J1=JS1,JF1,JSKIP1
         I=I+1
         JOPP = J1 + IOPP(IFC2)*IDIR
         X0(1) = XML(J1,J2,1,IE)
         X0(2) = YML(J1,J2,1,IE)
         X0(3) = ZML(J1,J2,1,IE)
C
         call prjects(x0,dxc,curve(1,ifce,ie),ccurve(ifce,ie))
         DX(1) = X0(1)-xml(j1,j2,1,ie)
         DX(2) = X0(2)-yml(j1,j2,1,ie)
         DX(3) = X0(3)-zml(j1,j2,1,ie)
         MXS = MXX(IFC2)
         JOFF = (J1-JOPP)/(MXS-1)
         DO 200 IX = 2,MXS
            J = JOPP + JOFF*(IX-1)
            ZETA = 0.5*(ZGML(IX,1) + 1.0)
            XML(J,J2,1,IE) = XML(J,J2,1,IE)+DX(1)*ZETA
            YML(J,J2,1,IE) = YML(J,J2,1,IE)+DX(2)*ZETA
            ZML(J,J2,1,IE) = ZML(J,J2,1,IE)+DX(3)*ZETA
  200    CONTINUE
  300 CONTINUE
C
      RETURN
      END
c-----------------------------------------------------------------------
      subroutine prjects(x0,dxc,c,cc)
c
c     Project the point x0 onto surface described by characteristics
c     given in the array c and cc.
c
c     dxc - characteristic length scale used to estimate gradient.
c
      real x0(3)
      real c(5)
      character*1 cc
      real x1(3)
      logical if3d
c
      if3d = .true.
      if (dxc.le.0.0) then
         write(6,*) 'invalid dxc',dxc,x0
         write(6,*) 'Abandoning prjects'
         return
      endif
c
      call copy(x1,x0,3)
      R0 = ressrf(x0,c,cc)
      if (r0.eq.0) return
c
c     Must at least use ctr differencing to capture symmetry!
c
      x1(1) = x0(1) - dxc
      R1 = ressrf(x1,c,cc)
      x1(1) = x0(1) + dxc
      R2 = ressrf(x1,c,cc)
      x1(1) = x0(1)
      Rx = 0.5*(R2-R1)/dxc
c
      x1(2) = x0(2) - dxc
      R1 = ressrf(x1,c,cc)/dxc
      x1(2) = x0(2) + dxc
      R2 = ressrf(x1,c,cc)/dxc
      x1(2) = x0(2)
      Ry = 0.5*(R2-R1)/dxc
c
      if (if3d) then
         x1(3) = x0(3) - dxc
         R1 = ressrf(x1,c,cc)/dxc
         x1(3) = x0(3) + dxc
         R2 = ressrf(x1,c,cc)/dxc
         Rz = 0.5*(R2-R1)/dxc
      endif
      Rnorm2 = Rx**2 + Ry**2 + Rz**2
      alpha  = - R0/Rnorm2
c
c     Apply secant method:  Use an initial segment twice expected length
c
      x1(1) = x0(1) + 2.0*Rx * alpha
      x1(2) = x0(2) + 2.0*Ry * alpha
      x1(3) = x0(3) + 2.0*Rz * alpha
      call srfind(x1,x0,c,cc)
c
c     write(6,6) cc,c(2),c(3),x0,x1
c   6 format(1x,a1,1x,2f5.2,3f9.4,3x,3f9.4)
c
      call copy(x0,x1,3)
c
      return
      end
c-----------------------------------------------------------------------
      subroutine srfind(x1,x0,c,cc)
      real x1(3),x0(3)
      real c(5)
      character*1 cc
c
c     Find point on line segment that intersects the ellipsoid
c     specified by:
c                       (x/a)**2 + (y/b)**2 + (z/b)**2 = 1
c
c
c     Algorithm:  4 rounds of secant  x_k+1 = x_k - f/f'
c
      a0 = 0.0
      a1 = 1.0
      r0 = ressrf(x0,c,cc)
      dx = x1(1) - x0(1)
      dy = x1(2) - x0(2)
      dz = x1(3) - x0(3)
c     write(6,*) 'dxyz',dx,dy,dz
c     write(6,*) 'cc  ',x0,cc,c(2),c(3)
      do 10 i=1,9
         r1 = ressrf(x1,c,cc)
         if (r1.ne.r0) then
            da = r1*(a1-a0)/(r1-r0)
            r0 = r1
            a0 = a1
            a1 = a1 - da
         endif
         x1(1) = x0(1) + a1*dx
         x1(2) = x0(2) + a1*dy
         x1(3) = x0(3) + a1*dz
   10 continue
c     write(6,*) ' r1',r1,r0,a1
      return
      end
      function ressrf(x,c,cc)
      real x(3)
      real c(5)
      character*1 cc
c
      ressrf = 0.0
      if (cc.eq.'e') then
         a = c(2)
         b = c(3)
         ressrf = 1.0 - (x(1)/a)**2 - (x(2)/b)**2 - (x(3)/b)**2
         return
      endif
c
      return
      end
c-----------------------------------------------------------------------
