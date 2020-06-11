!=================
! Includes:
!     (1) Norm Calculation
!       (1.1) Norm calculation Parker and Youngs
!       (1.2) Norm calculation Central difference
!       (1.3) Norm calculation Mixed Central difference and Youngs (MYC)
!       (1.4) Norm calculation MOF interface
!     (2) Flooding algorithm
!       (2.1) Flooding algorithm forward
!       (2.2) Flooding algorithm backward
!     (3) MOF
!       (3.1) MOF iteration
!       (3.2) Find centroid for given norm and volume function
!       (3.3) Cartesian norm to Spherical angle
!       (3.4) Spherical angle to Cartesian norm
!       (3.5) Anvance of angle
!     (4) Misc
!       (4.1) Normalization vector 1 (nx+ny+nz=1)
!       (4.2) Normalization vector 2 (nx**2+ny**2+nz**2=1)
!-----------------
! Note:
!    (1) We now only consider the uniform Certasian grid with x0(1:3) = 0,
!        and dx(1:3) = 1. In MOF, although x0(1:3) = -0.5, origin shifts are
!     done on MOF interface (1.4).
!    (2) If applied to non-uniform grid, either need to modify the code,
!        or need to do a coordinate transformation to insure the input data
!        satisfies the requirement.
!=================
Module MOD_VOFFunc
  Implicit None

  ! MOF iteration parameters
  Real(sp), Parameter :: MOFITERMAX = 10
  Real(sp), Parameter :: tol = 1.0e-8
  Real(sp), Parameter :: local_tol = 1.0e-8
  Real(sp), Parameter :: CenTol = 1e-13
  ! Real(sp), Parameter :: GaussNewtonTol = 1e-13
  Real(sp), Parameter :: MOF_Pi = 3.1415926535897932d0
Contains

!=======================================================
! (1.1) Normal vector Youngs (1992)
!-------------------------------------------------------
! Input: f (vof function, 3*3*3 stencil)
! Output: norm (normal vector)
!=======================================================
Subroutine NormParkerYoungs(f, norm)
  Use ModGlobal, only : sp
  Implicit None
  Real(sp), Intent(In)   :: F(3,3,3)
  Real(sp), Intent(Out)  :: norm(3)
  Real(sp) :: mm1, mm2
  norm(3) = 0.0_sp
  mm1 = f(1,1,1)+f(1,1,3)+f(1,3,1) & 
      +f(1,3,3)+2.0_sp*(f(1,1,2)+f(1,3,2)&
      +f(1,2,1)+f(1,2,3))+4.0_sp*f(1,2,2)
  mm2 = f(3,1,1)+f(3,1,3)+f(3,3,1) &
      +f(3,3,3)+2.0_sp*(f(3,1,2)+f(3,3,2) &
      +f(3,2,1)+f(3,2,3))+4.0_sp*f(3,2,2)
  norm(1) = mm1 - mm2

  mm1 = f(1,1,1)+f(1,1,3)+f(3,1,1) &
      +f(3,1,3)+2.0_sp*(f(1,1,2)+f(3,1,2) &
      +f(2,1,1)+f(2,1,3))+4.0_sp*f(2,1,2)
  mm2 = f(1,3,1)+f(1,3,3)+f(3,3,1) &
      +f(3,3,3)+2.0_sp*(f(1,3,2)+f(3,3,2) &
      +f(2,3,1)+f(2,3,3))+4.0_sp*f(2,3,2)
  norm(2) = mm1 - mm2

  mm1 = f(1,1,1)+f(1,3,1)+f(3,1,1) &
      +f(3,3,1)+2.0_sp*(f(1,2,1)+f(3,2,1) &
      +f(2,1,1)+f(2,3,1))+4.0_sp*f(2,2,1)
  mm2 = f(1,1,3)+f(1,3,3)+f(3,1,3) &
      +f(3,3,3)+2.0_sp*(f(1,2,3)+f(3,2,3) &
      +f(2,1,3)+f(2,3,3))+4.0_sp*f(2,2,3)
  norm(3) = mm1 - mm2

End Subroutine NormParkerYoungs

!=======================================================
! (1.2) Normal vector Central Scheme
! * returns normal normalized so that |mx|+|my|+|mz| = 1*
! Adopted from Paris Simulator by Zakeski
!-------------------------------------------------------
! Input: c (vof function, 3*3*3 stencil)
! Output: norm (normal vector)
!=======================================================
Subroutine NormCS(c,norm)
  !***
  Implicit None
  Real(8) c(3,3,3)
  Real(8) norm(3), abs_norm(3)
  Real(8) m1,m2,m(0:3,0:2),t0,t1,t2
  Integer cn

  ! write the plane as: sgn(mx) X =  my Y +  mz Z + alpha 
  !                           m00 X = m01 Y + m02 Z + alpha 

  m1 = c(1,2,1) + c(1,2,3) + c(1,1,2) + c(1,3,2) + &
      c(1,2,2)
  m2 = c(3,2,1) + c(3,2,3) + c(3,1,2) + c(3,3,2) + &
      c(3,2,2)

  if(m1>m2) then
    m(0,0) = 1.
  else
    m(0,0) = -1.
  end if

  m1 = c(1,1,2)+ c(3,1,2)+ c(2,1,2)
  m2 = c(1,3,2)+ c(3,3,2)+ c(2,3,2)
  m(0,1) = 0.5*(m1-m2)

  m1 = c(1,2,1)+ c(3,2,1)+ c(2,2,1)
  m2 = c(1,2,3)+ c(3,2,3)+ c(2,2,3)
  m(0,2) = 0.5*(m1-m2)

  ! write the plane as: sgn(my) Y =  mx X +  mz Z + alpha, 
  !                          m11 Y = m10 X + m12 Z + alpha.
  m1 = c(1,1,2) + c(1,3,2) + c(1,2,2)
  m2 = c(3,1,2) + c(3,3,2) + c(3,2,2)
  m(1,0) = 0.5*(m1-m2)

  m1 = c(2,1,1) + c(2,1,3) + c(3,1,2) + c(1,1,2) +&
      c(2,1,2)
  m2 = c(2,3,1) + c(2,3,3) + c(3,3,2) + c(1,3,2) +&
      c(2,3,2)

  if(m1>m2) then
    m(1,1) = 1.
  else
    m(1,1) = -1.
  end if

  m1 = c(2,1,1)+ c(2,2,1)+ c(2,3,1)
  m2 = c(2,1,3)+ c(2,2,3)+ c(2,3,3)
  m(1,2) = 0.5*(m1-m2)

  m1 = c(1,2,1)+ c(1,2,3)+ c(1,2,2)
  m2 = c(3,2,1)+ c(3,2,3)+ c(3,2,2)
  m(2,0) = 0.5*(m1-m2)

  m1 = c(2,1,1)+ c(2,1,3)+ c(2,1,2)
  m2 = c(2,3,1)+ c(2,3,3)+ c(2,3,2)
  m(2,1) = 0.5*(m1-m2)

  m1 = c(1,2,1) + c(3,2,1) + c(2,1,1) + c(2,3,1) +&
      c(2,2,1)
  m2 = c(1,2,3) + c(3,2,3) + c(2,1,3) + c(2,3,3) +&
      c(2,2,3)

  if(m1>m2) then
    m(2,2) = 1.
  else
    m(2,2) = -1.
  end if

  ! normalize each set (mx,my,mz): |mx|+|my|+|mz| = 1

  t0 = DABS(m(0,0)) + DABS(m(0,1)) + DABS(m(0,2))
  m(0,0) = m(0,0)/t0
  m(0,1) = m(0,1)/t0
  m(0,2) = m(0,2)/t0

  t0 = DABS(m(1,0)) + DABS(m(1,1)) + DABS(m(1,2))
  m(1,0) = m(1,0)/t0
  m(1,1) = m(1,1)/t0
  m(1,2) = m(1,2)/t0

  t0 = DABS(m(2,0)) + DABS(m(2,1)) + DABS(m(2,2))
  m(2,0) = m(2,0)/t0
  m(2,1) = m(2,1)/t0
  m(2,2) = m(2,2)/t0

  ! choose among the three central schemes */ 
  t0 = DABS(m(0,0))
  t1 = DABS(m(1,1))
  t2 = DABS(m(2,2))

  cn = 0
  if (t1 > t0) then
    t0 = t1
    cn = 1
  endif

  if (t2 > t0) cn = 2

  ! components of the normal vector */
  norm(1) = m(cn,0)
  norm(2) = m(cn,1)
  norm(3) = m(cn,2)

  return
End Subroutine NormCS

!=======================================================
! (1.3) Mixed Youngs and Central difference
! * returns normal normalized so that |mx|+|my|+|mz| = 1*
! Adopted from Paris Simulator by Zakeski
!-------------------------------------------------------
! Input: c (vof function, 3*3*3 stencil)
! Output: norm (normal vector)
!=======================================================
Subroutine NormMYCS(c,norm)
  !***
  Implicit None
  Real(8) c(3,3,3)
  Real(8) norm(3), abs_norm(3)
  Real(8) m1,m2,m(0:3,0:2),t0,t1,t2
  Real(8) mm(3), abs_mm(3)
  Integer cn
  ! write the plane as: sgn(mx) X =  my Y +  mz Z + alpha 
  !                           m00 X = m01 Y + m02 Z + alpha 

  m1 = c(1,2,1) + c(1,2,3) + c(1,1,2) + c(1,3,2) + &
      c(1,2,2)
  m2 = c(3,2,1) + c(3,2,3) + c(3,1,2) + c(3,3,2) + &
      c(3,2,2)

  if(m1>m2) then
    m(0,0) = 1.
  else
    m(0,0) = -1.
  end if

  m1 = c(1,1,2)+ c(3,1,2)+ c(2,1,2)
  m2 = c(1,3,2)+ c(3,3,2)+ c(2,3,2)
  m(0,1) = 0.5*(m1-m2)

  m1 = c(1,2,1)+ c(3,2,1)+ c(2,2,1)
  m2 = c(1,2,3)+ c(3,2,3)+ c(2,2,3)
  m(0,2) = 0.5*(m1-m2)

  ! write the plane as: sgn(my) Y =  mx X +  mz Z + alpha, 
  !                          m11 Y = m10 X + m12 Z + alpha.
  m1 = c(1,1,2) + c(1,3,2) + c(1,2,2)
  m2 = c(3,1,2) + c(3,3,2) + c(3,2,2)
  m(1,0) = 0.5*(m1-m2)

  m1 = c(2,1,1) + c(2,1,3) + c(3,1,2) + c(1,1,2) +&
      c(2,1,2)
  m2 = c(2,3,1) + c(2,3,3) + c(3,3,2) + c(1,3,2) +&
      c(2,3,2)

  if(m1>m2) then
    m(1,1) = 1.
  else
    m(1,1) = -1.
  end if

  m1 = c(2,1,1)+ c(2,2,1)+ c(2,3,1)
  m2 = c(2,1,3)+ c(2,2,3)+ c(2,3,3)
  m(1,2) = 0.5*(m1-m2)

  m1 = c(1,2,1)+ c(1,2,3)+ c(1,2,2)
  m2 = c(3,2,1)+ c(3,2,3)+ c(3,2,2)
  m(2,0) = 0.5*(m1-m2)

  m1 = c(2,1,1)+ c(2,1,3)+ c(2,1,2)
  m2 = c(2,3,1)+ c(2,3,3)+ c(2,3,2)
  m(2,1) = 0.5*(m1-m2)

  m1 = c(1,2,1) + c(3,2,1) + c(2,1,1) + c(2,3,1) +&
      c(2,2,1)
  m2 = c(1,2,3) + c(3,2,3) + c(2,1,3) + c(2,3,3) +&
      c(2,2,3)

  if(m1>m2) then
    m(2,2) = 1.
  else
    m(2,2) = -1.
  end if

  ! normalize each set (mx,my,mz): |mx|+|my|+|mz| = 1

  t0 = DABS(m(0,0)) + DABS(m(0,1)) + DABS(m(0,2))
  m(0,0) = m(0,0)/t0
  m(0,1) = m(0,1)/t0
  m(0,2) = m(0,2)/t0

  t0 = DABS(m(1,0)) + DABS(m(1,1)) + DABS(m(1,2))
  m(1,0) = m(1,0)/t0
  m(1,1) = m(1,1)/t0
  m(1,2) = m(1,2)/t0

  t0 = DABS(m(2,0)) + DABS(m(2,1)) + DABS(m(2,2))
  m(2,0) = m(2,0)/t0
  m(2,1) = m(2,1)/t0
  m(2,2) = m(2,2)/t0

  ! choose among the three central schemes */ 
  t0 = DABS(m(0,0))
  t1 = DABS(m(1,1))
  t2 = DABS(m(2,2))

  cn = 0
  if (t1 > t0) then
    t0 = t1
    cn = 1
  endif

  if (t2 > t0) cn = 2

  ! Youngs-CIAM scheme */
  Call NormParkerYoungs(c,mm,abs_mm)
  m(3,0:2) = mm(1:3)

  ! ! choose between the previous choice and Youngs-CIAM 
  if (DABS(m(cn,cn)) > maxval(abs_mm))  cn = 3

  ! components of the normal vector */
  norm(1:3) = m(cn,0:2)

  return
End Subroutine NormMYCS

!===============================================================
! (1.4) Interface for Normal vector MOF
!-------------------------------------------------------
! Input: f (vof function, only 1 element)
! Input: c (centroid, x,y,z)
! Output: norm (normal vector, nx, ny, nz)
!===============================================================
Subroutine NormMOF(f,c,norm)
  Use ModMOF
  Implicit None
  Real(8), Intent(In) :: f
  Real(8), Intent(In) :: c(3)
  Real(8), Intent(Out) :: norm(3), abs_norm(3)
  Call NormSussmanMOF(f,c,norm)
  Call Normalization1(norm)
End Subroutine NormMOF
!=======================================================
! Backward flooding algorithm of SZ.
! find alpha in
!    m1 x1 + m2 x2 + m3 x3 = alpha
!=======================================================
Real(sp) Function FloodSZ_Backward(nr,cc) 
  Use ModGlobal, only : sp
  Implicit None
 REAL(8), INTENT(IN):: nr(3),cc
  REAL(8) :: cch,c01,c02,c03,np1,np2,np3
  REAL(8) :: m1,m2,m3,m12,numer,denom,p,pst,q,arc,csarc, alpha
  REAL(8), PARAMETER :: athird=1.d0/3.d0,eps0=1.d-50 
  INTRINSIC DABS,DMIN1,DMAX1,DSQRT,DACOS,DCOS

  np1 = DABS(nr(1))                                 ! need positive coefficients
  np2 = DABS(nr(2))
  np3 = DABS(nr(3))
  m1 = DMIN1(np1,np2)                              ! order positive coefficients
  m3 = DMAX1(np1,np2)
  if (np3 < m1) then
     m2 = m1
     m1 = np3
  else if (np3 >= m3) then
     m2 = m3
     m3 = np3
   else
     m2 = np3
  endif

  denom = DMAX1(6.d0*m1*m2*m3,eps0)                           
  cch = DMIN1(cc,1.d0-cc)                              ! limit to: 0 < cch < 1/2
  c01 = m1*m1*m1/denom                                          ! get cch ranges
  c02  = c01 + 0.5d0*(m2-m1)/m3
  m12 = m1 + m2
  if (m12 <= m3) then
     c03 = 0.5d0*m12/m3
  else
     numer = m3*m3*(3.d0*m12-m3) + m1*m1*(m1-3.d0*m3) + m2*m2*(m2-3.d0*m3)
     c03 = numer/denom
  endif

! 1: C<=C1; 2: C1<=C<=C2; 3: C2<=C<=C3; 4: C3<=C<=1/2 (a: m12<=m3; b: m3<m12)) 
  if (cch <= c01) then
     alpha = (denom*cch)**athird                                       ! case (1)
  else if (cch <= c02) then 
     alpha = 0.5d0*(m1 + DSQRT(m1*m1 + 8.d0*m2*m3*(cch-c01)))          ! case (2)
  else if (cch <= c03) then
     p = 2.d0*m1*m2
     q = 1.5d0*m1*m2*(m12 - 2.d0*m3*cch)
     pst = DSQRT(p)
     arc = athird*DACOS(q/(p*pst))
     csarc = DCOS(arc)
     alpha = pst*(DSQRT(3.d0*(1.d0-csarc*csarc)) - csarc) + m12        ! case (3)
  else if (m12 <= m3) then
     alpha = m3*cch + 0.5d0*m12                                       ! case (4a)
  else
     p = m12*m3 + m1*m2 - 0.25d0
     q = 1.5d0*m1*m2*m3*(0.5d0-cch)
     pst = DSQRT(p)
     arc = athird*DACOS(q/(p*pst))
     csarc = DCOS(arc)
     alpha = pst*(DSQRT(3.d0*(1.d0-csarc*csarc)) - csarc) + 0.5d0     ! case (4b)
  endif

  if (cc > 0.5d0)  alpha = 1.d0 - alpha

  FloodSZ_backward = alpha
  FloodSZ_backward = alpha + DMIN1(0.0_sp,nr(1)) + DMIN1(0.0_sp,nr(2)) + &
      &                 DMIN1(0.0_sp,nr(3))
  return
end FUNCTION FloodSZ_Backward

!=======================================================
! Forward flooding algorithm of SZ
! FIND THE "CUT VOLUME" V0
! for GIVEN
!    r0, dr0
!  and
!    m1 x1 + m2 x2 + m3 x3 = alpha
!=======================================================
Real(sp) Function FloodSZ_forward(nr,alpha,x0,dx)
  Use ModGlobal, only : sp
  IMPLICIT NONE
  REAL(sp), INTENT(IN):: nr(3),x0(3),dx(3),alpha
  REAL(sp) :: al,almax,alh,np1,np2,np3,m1,m2,m3,m12,mm,denom,frac,top
  REAL(sp), PARAMETER :: eps0=1.d-50 
  INTRINSIC DMAX1,DMIN1,DABS

! move origin to x0 
  al = alpha - nr(1)*x0(1) - nr(2)*x0(2) - nr(3)*x0(3)
! reflect the figure when negative coefficients
  al = al + DMAX1(0.d0,-nr(1)*dx(1)) + DMAX1(0.d0,-nr(2)*dx(2)) &
          + DMAX1(0.d0,-nr(3)*dx(3)) 
  np1 = DABS(nr(1))                                 ! need positive coefficients
  np2 = DABS(nr(2))
  np3 = DABS(nr(3))
  almax = np1*dx(1) + np2*dx(2) + np3*dx(3)                       
  al = DMAX1(0.d0,DMIN1(1.d0,al/almax))           !get new al within safe limits
  alh = DMIN1(al,1.d0-al)                              ! limit to: 0 < alh < 1/2


! normalized equation: m1*y1 + m2*y2 + m3*y3 = alh, with 0 <= m1 <= m2 <= m3
! the problem is then solved again in the unit cube
  np1 = np1/almax;
  np2 = np2/almax;
  np3 = np3/almax;
  m1 = DMIN1(np1*dx(1),np2*dx(2))                           ! order coefficients
  m3 = DMAX1(np1*dx(1),np2*dx(2))
  top = np3*dx(3)
  if (top < m1) then
     m2 = m1
     m1 = top
  else if (top >= m3) then
     m2 = m3
     m3 = top
   else
     m2 = top
  endif

  m12 = m1 + m2
  mm = DMIN1(m12,m3)
  denom = DMAX1(6.d0*m1*m2*m3,eps0)

! 1: al<=m1; 2: m1<=al<=m2; 3: m2<=al<=mm; 4: mm<=al<=1/2 (a:m12<=m3; b:m3<m12)) 
  if (alh <= m1) then
     frac = alh*alh*alh/denom                                         ! case (1)
  else if (alh <= m2) then
     frac = 0.5d0*alh*(alh-m1)/(m2*m3) +  m1*m1*m1/denom              ! case (2)
  else if (alh <= mm) then
     top = alh*alh*(3.d0*m12-alh) + m1*m1*(m1-3.d0*alh)              
     frac = (top + m2*m2*(m2-3.d0*alh))/denom                         ! case (3)
  else if (m12 <= m3) then
     frac = (alh - 0.5d0*m12)/m3                                     ! case (4a)
  else
     top = alh*alh*(3.d0-2.d0*alh) + m1*m1*(m1-3.d0*alh)             
     frac = (top + m2*m2*(m2-3.d0*alh) + m3*m3*(m3-3.d0*alh))/denom  ! case (4b)
  endif

  top = dx(1)*dx(2)*dx(3)
  if (al <= 0.5d0) then
     FloodSZ_forward = frac*top
  else
     FloodSZ_forward = (1.d0-frac)*top
  endif

end FUNCTION FloodSZ_forward

!=======================================================
! Forward flooding algorithm of APPLIC.
! FIND THE "CUT VOLUME" V0
! for GIVEN
!    r0, dr0
!  and
!    m1 x1 + m2 x2 + m3 x3 = alpha
! also
!   the centroid x,y,z
!=======================================================
SUBROUTINE FloodSZ_forwardC(nr,alpha,x0,dx,f,xc0)

  IMPLICIT NONE
  REAL(8), INTENT(IN) :: nr(3),x0(3),dx(3),alpha
  REAL(8), INTENT(OUT) :: f
  REAL(8), INTENT(OUT) :: xc0(3)
  REAL(8) :: ctd0(3)
  REAL(8) :: al,almax,alh,alr,np1,np2,np3,m1,m2,m3,m12,mm,denom
  REAL(8) :: tmp1,tmp2,tmp3,tmp4,a2,bot1,frac
  REAL(8), PARAMETER :: eps0=1.d-50
  INTEGER :: ind(3)
  INTRINSIC DMAX1,DMIN1,DABS

! move origin to x0 
  al = alpha - nr(1)*x0(1) - nr(2)*x0(2) - nr(3)*x0(3)
! reflect the figure when negative coefficients
  al = al + DMAX1(0.d0,-nr(1)*dx(1)) + DMAX1(0.d0,-nr(2)*dx(2)) &
          + DMAX1(0.d0,-nr(3)*dx(3)) 
  np1 = DABS(nr(1))                                 ! need positive coefficients
  np2 = DABS(nr(2))
  np3 = DABS(nr(3))
  almax = np1*dx(1) + np2*dx(2) + np3*dx(3)                       
  al = DMAX1(0.d0,DMIN1(1.d0,al/almax))           !get new al within safe limits
  alh = DMIN1(al,1.d0-al)                              ! limit to: 0 < alh < 1/2
  alr = DMAX1(alh,eps0)                                     ! avoid alh = m1 = 0

! normalized equation: m1*y1 + m2*y2 + m3*y3 = alh, with 0 <= m1 <= m2 <= m3
! the problem is then solved again in the unit cube
  np1 = np1*dx(1)/almax;
  np2 = np2*dx(2)/almax;
  np3 = np3*dx(3)/almax;
! coefficients in ascending order
  if (np1 <= np2) then
    m1 = np1
    m3 = np2
    ind(1) = 1
    ind(3) = 2
  else
    m1 = np2
    m3 = np1
    ind(1) = 2
    ind(3) = 1
  endif

  if (np3 < m1) then
    m2 = m1
    m1 = np3
    ind(2) = ind(1)
    ind(1) = 3
  else if (np3 >= m3) then
    m2 = m3
    m3 = np3
    ind(2) = ind(3)
    ind(3) = 3
  else
    m2 = np3
    ind(2) = 3
  endif

  m12 = m1 + m2
  mm = DMIN1(m12,m3)
  denom = DMAX1(6.d0*m1*m2*m3,eps0)

! 1: al<=m1; 2: m1<=al<=m2; 3: m2<=al<=mm; 4: mm<=al<=1/2 (a:m12<=m3; b:m3<m12)) 
  if (alr <= m1) then
    tmp1 = 0.25d0*alh
    ctd0(1) = tmp1/m1 
    ctd0(2) = tmp1/m2
    ctd0(3) = tmp1/m3                                                
    frac = alh*alh*alh/denom                                          ! case (1)
  else if (alr <= m2) then
    tmp1 = (2.d0*alh-m1)
    tmp2 = (2.d0*alh*alh - 2.d0*alh*m1 + m1*m1)
    bot1 = 4.d0*(3.d0*alr*alr - 3.d0*alh*m1 + m1*m1)
    tmp2 = tmp1*tmp2/bot1
    ctd0(1) = 0.5d0 - m1*tmp1/bot1 
    ctd0(2) = tmp2/m2
    ctd0(3) = tmp2/m3                                                
    frac = 0.5d0*alh*(alh-m1)/(m2*m3) +  m1*m1*m1/denom               ! case (2)
  else if (alr <= mm) then
    a2 = alh*alh
    tmp1 = (alh-m1)*(alh-m1)*(alh-m1)
    tmp2 = (alh-m2)*(alh-m2)*(alh-m2)
    bot1 = 4.d0*(a2*alh - tmp1 - tmp2)
    ctd0(1) = (a2*a2 - tmp1*(alh+3.d0*m1) - tmp2*(alh-m2))/(m1*bot1) 
    ctd0(2) = (a2*a2 - tmp1*(alh-m1) - tmp2*(alh+3.d0*m2))/(m2*bot1) 
    ctd0(3) = (a2*a2 - tmp1*(alh-m1) - tmp2*(alh-m2))/(m3*bot1)      
    tmp3 = alh*alh*(3.d0*m12-alh) + m1*m1*(m1-3.d0*alh)              
    frac = (tmp3 + m2*m2*(m2-3.d0*alh))/denom                         ! case (3)
  else if (m12 <= m3) then
    bot1 = DMAX1((2.d0*alh - m12),eps0)
    ctd0(1) = 0.5d0 - m1/(6.d0*bot1)
    ctd0(2) = 0.5d0 - m2/(6.d0*bot1)                                
    ctd0(3) = ((3.d0*alh - 2.d0*m12)*bot1 + alh*m12 - m1*m2)/(6.d0*m3*bot1)
    frac = (alh - 0.5d0*m12)/m3                                      ! case (4a)
  else
    tmp1 = m1 + m2 + m3
    tmp2 = m1*m1 + m2*m2 + m3*m3
    tmp3 = m1*m1*m1 + m2*m2*m2 + m3*m3*m3
    tmp4 = m1*m1*m1*m1 + m2*m2*m2*m2 + m3*m3*m3*m3
    a2 = alh*alh
    bot1 = 4.d0*(2.d0*a2*alh - 3.d0*a2*tmp1 + 3.d0*alh*tmp2 - tmp3)
    tmp1 = 2.d0*a2*a2 - 4.d0*a2*alh*tmp1 + 6.d0*a2*tmp2 - 4.d0*alh*tmp3 + tmp4
    ctd0(1) = (tmp1 + 4.d0*m1*(alh-m1)*(alh-m1)*(alh-m1))/(m1*bot1)
    ctd0(2) = (tmp1 + 4.d0*m2*(alh-m2)*(alh-m2)*(alh-m2))/(m2*bot1)
    ctd0(3) = (tmp1 + 4.d0*m3*(alh-m3)*(alh-m3)*(alh-m3))/(m3*bot1) 
    tmp1 = alh*alh*(3.d0-2.d0*alh) + m1*m1*(m1-3.d0*alh)             
    frac = (tmp1 + m2*m2*(m2-3.d0*alh) + m3*m3*(m3-3.d0*alh))/denom  ! case (4b)
  endif

! back to actual al value, but the centroid of a full cell is the cell center
! must be careful that frac = cc when al < 0.5, otherwise frac = 1 - cc
  if (al > 0.5d0) then
    ctd0(1) = (0.5d0 - frac*(1.d0-ctd0(1)))/(1.d0-frac)
    ctd0(2) = (0.5d0 - frac*(1.d0-ctd0(2)))/(1.d0-frac)
    ctd0(3) = (0.5d0 - frac*(1.d0-ctd0(3)))/(1.d0-frac)
  endif

! get correct indexing
  xc0(ind(1)) = ctd0(1)                              
  xc0(ind(2)) = ctd0(2)
  xc0(ind(3)) = ctd0(3)

! take care of negative coefficients
  if (nr(1) < 0.d0) xc0(1) = 1.d0 - xc0(1) 
  if (nr(2) < 0.d0) xc0(2) = 1.d0 - xc0(2)
  if (nr(3) < 0.d0) xc0(3) = 1.d0 - xc0(3)

! final position of the centroid with respect to the cell origin
! and by considering the actual sides of the hexahedron 
  xc0(1) = x0(1) + xc0(1)*dx(1) 
  xc0(2) = x0(2) + xc0(2)*dx(2) 
  xc0(3) = x0(3) + xc0(3)*dx(3) 

  if (al <= 0.5d0) then
    f = frac * dx(1)*dx(2)*dx(3)
  else
    f = (1.d0-frac) * dx(1)*dx(2)*dx(3)
  endif

End Subroutine FloodSZ_forwardC

!===========================
! (4.1) MOF Reconstruction using Gauss-Newtoan iteration
!
!
!===========================
Subroutine MOFZY(f, c, norm)
  Implicit None

  Real(sp), Intent(In)  :: f
  Real(sp), Intent(In)  :: c(3)
  Real(sp), Intent(Out) :: norm(3)

  Real(sp), Dimension(3)   :: norm_2
  Real(sp) :: delta_theta
  Real(sp) :: delta_theta_max
  Real(sp), Dimension(2)   :: delangle, angle_init, angle_previous, new_angle
  Real(sp), Dimension(2)   :: angle_base, angle_plus, angle_minus
  Real(sp), Dimension(2)   :: err_plus, err_minus
  Real(sp), Dimension(3)   :: dbase, dopt, dp, dm
  Real(sp), Dimension(3,2) :: d_plus, d_minus
  Real(sp), Dimension(3)   :: cenopt, cenp, cenm, cen_init
  Real(sp), Dimension(3,2) :: cen_plus, cen_minus
  Real(sp), Dimension(3,2) :: dgrad
  Real(sp), Dimension(2,2) :: JTJ, JTJINV
  Real(sp), Dimension(2)   :: RHS
  Real(sp) :: DET
  Real(sp), Dimension(3,MOFITERMAX+1) :: d_array, cen_array
  Real(sp), Dimension(2,MOFITERMAX+1) :: angle_array
  Real(sp), Dimension(MOFITERMAX+1)   :: err_array

  Real(sp) :: err, err_local_min
  Real(sp) :: scale
  Integer :: singular_flag
  Integer :: i_angle, j_angle, dir, iter, niter, i

  ! Setting the initial guess as 0
  norm(1) = 2.0_sp / 6.0_sp
  norm(2) = 2.0_sp / 6.0_sp
  norm(3) = 2.0_sp / 6.0_sp

  scale = 1.0_sp / sqrt(abs(norm(1)**2 + abs(norm(2))**2 + abs(norm(3))**2))
  norm_2 = norm * scale

  Call Norm2Angle(angle_init,norm_2)

  angle_init(1) = 3.1_sp
  angle_init(2) = 0.1_sp


  do dir=1,2
    angle_array(dir,1)= angle_init(dir)
  enddo
  Call FindCentroid(angle_init,f,cen_init)
  do dir=1,3
    d_array(dir,1) = c(dir) - cen_init(dir)
    cen_array(dir,1)=cen_init(dir)
    err_array(1)=err_array(1) + d_array(dir,1) * d_array(dir,1)
  enddo

  delta_theta = MOF_Pi / 180.0  ! 1 degree=pi/180
  delta_theta_max = 10.0 * MOF_Pi / 180  ! 10 degrees

  iter = 0
  err = err_array(1)
  err_local_min = err_array(1)
  Do While ((iter.lt.MOFITERMAX).and. &
      (err.gt.tol).and. &
      (err_local_min.gt.local_tol))

    do dir=1,3
      dbase(dir)=d_array(dir,iter+1)
    enddo

    do i_angle=1,2
      angle_base(i_angle)=angle_array(i_angle,iter+1)
    enddo

    Do i_angle=1,2

      Do j_angle=1,2
        angle_plus(j_angle)=angle_base(j_angle)
        angle_minus(j_angle)=angle_base(j_angle)
      End Do
      angle_plus(i_angle)=angle_plus(i_angle)+delta_theta
      angle_minus(i_angle)=angle_minus(i_angle)-delta_theta
      Call FindCentroid(angle_plus,f,cenp)
      err_plus(i_angle)= 0.0_sp
      do dir=1,3
        dp(dir) = c(dir) - cenp(dir)
        err_plus(i_angle)=err_plus(i_angle)+dp(dir)**2
        d_plus(dir,i_angle)=dp(dir)
        cen_plus(dir,i_angle)=cenp(dir)
      end do
      err_plus(i_angle)=sqrt(err_plus(i_angle))
      Call FindCentroid(angle_minus,f,cenm)
      err_minus(i_angle)= 0.0_sp
      do dir=1,3
        dm(dir) = c(dir) - cenm(dir)
        err_minus(i_angle)=err_minus(i_angle)+dm(dir)**2
        d_minus(dir,i_angle)=dm(dir)
        cen_minus(dir,i_angle)=cenm(dir)
      enddo
      err_minus(i_angle)=sqrt(err_minus(i_angle))
!!! jacobian matrix has:
      do dir=1,3
        dgrad(dir,i_angle)=(dp(dir)-dm(dir))/(2.0_sp*delta_theta)
      enddo

    End Do

    Do i_angle=1,2
      Do j_angle=1,2
        JTJ(i_angle,j_angle)= 0.0_sp
        Do dir=1,3
          JTJ(i_angle,j_angle)=JTJ(i_angle,j_angle)+ &
              dgrad(dir,i_angle)*dgrad(dir,j_angle)
        EndDo
      EndDo
    EndDo

    DET=JTJ(1,1)*JTJ(2,2)-JTJ(1,2)*JTJ(2,1)
    ! DET has dimensions of length squared
    if (abs(DET).ge.CENTOL) then 
      singular_flag=0
    else if (abs(DET).le.CENTOL) then
      singular_flag=1
    else
      print *,"DET bust"
      stop
    endif

    if (singular_flag.eq.0) then
      JTJINV(1,1)=JTJ(2,2)
      JTJINV(2,2)=JTJ(1,1)
      JTJINV(1,2)=-JTJ(1,2)
      JTJINV(2,1)=-JTJ(2,1)

      do i_angle=1,2
        do j_angle=1,2
          JTJINV(i_angle,j_angle)=JTJINV(i_angle,j_angle)/DET
        enddo
      enddo

      do i_angle=1,2  ! compute -JT * r
        RHS(i_angle)= 0.0_sp
        do dir=1,3
          RHS(i_angle)=RHS(i_angle)-dgrad(dir,i_angle)*dbase(dir)
        enddo
      enddo

      err_local_min= 0.0_sp
      do i_angle=1,2
        err_local_min=err_local_min+RHS(i_angle)**2
      enddo
      err_local_min=sqrt(err_local_min)

      do i_angle=1,2  ! compute JTJ^-1 (RHS)
        delangle(i_angle)= 0.0_sp
        do j_angle=1,2
          delangle(i_angle)=delangle(i_angle)+ &
              JTJINV(i_angle,j_angle)*RHS(j_angle)
        enddo
        if (delangle(i_angle).gt.delta_theta_max) then
          delangle(i_angle)=delta_theta_max
        else if (delangle(i_angle).lt.-delta_theta_max) then
          delangle(i_angle)=-delta_theta_max
        endif
      enddo
      ! -pi<angle<pi
      do i_angle=1,2
        angle_previous(i_angle)=angle_base(i_angle)
        call advance_angle(angle_base(i_angle),delangle(i_angle))
      enddo
      Call FindCentroid(angle_base,f, cenopt)
      do dir=1,3
        dopt(dir) = c(dir) - cenopt(dir)
      enddo

    else if (singular_flag.eq.1) then
      err_local_min= 0.0_sp

      do dir=1,3
        dopt(dir)=dbase(dir)
      enddo
      do i_angle=1,2
        angle_base(i_angle)=angle_array(i_angle,iter+1)
      enddo
    else
      print *,"singular_flag invalid"
      stop
    End If

    err= 0.0_sp
    do dir=1,3
      err=err+dopt(dir)**2
    enddo
    err=sqrt(err)

    if (singular_flag.eq.1) then
      ! do nothing
    else if (singular_flag.eq.0) then
      do i_angle=1,2
        do j_angle=1,2
          angle_plus(j_angle)=angle_previous(j_angle)
          angle_minus(j_angle)=angle_previous(j_angle)
        enddo
        angle_plus(i_angle)=angle_plus(i_angle)+delta_theta
        angle_minus(i_angle)=angle_minus(i_angle)-delta_theta

        if ((err.le.err_plus(i_angle)).and. &
            (err.le.err_minus(i_angle))) then
          ! do nothing
        else

          if (err.ge.err_plus(i_angle)) then
            err=err_plus(i_angle)
            do dir=1,3
              dopt(dir)=d_plus(dir,i_angle)
              cenopt(dir)=cen_plus(dir,i_angle)
            enddo
            do j_angle=1,2
              angle_base(j_angle)=angle_plus(j_angle)
            enddo
          endif

          if (err.ge.err_minus(i_angle)) then
            err=err_minus(i_angle)
            do dir=1,3
              dopt(dir)=d_minus(dir,i_angle)
              cenopt(dir)=cen_minus(dir,i_angle)
            enddo
            do j_angle=1,2
              angle_base(j_angle)=angle_minus(j_angle)
            enddo
          endif

        endif ! use safe update

      enddo ! i_angle     if (singular_flag.eq.1) then
    else
      print *,"singular_flag invalid"
      stop
    endif

    do dir=1,3
      d_array(dir,iter+2)=dopt(dir)
      cen_array(dir,iter+2)=cenopt(dir)
    enddo

    do i_angle=1,2
      angle_array(i_angle,iter+2)=angle_base(i_angle)
    enddo
    err_array(iter+2)=err
    iter=iter+1
    print *, '=====step',iter,'=========='
    print *, cen_array(:,iter+1)
    print *, angle_array(:,iter+1)
    print *, err_array(iter+1)
    print *, err, err_local_min
  End Do
  niter = iter+1


  ! do i = 1, niter
  !   print *, '=====step',i,'=========='
  !   print *, cen_array(:,i)
  !   print *, angle_array(:,i)
  !   print *, err_array(i)
  ! end do

  do dir=1,2
    new_angle(dir)=angle_array(dir,iter+1)
  enddo

  call Angle2Norm(new_angle,norm_2)

  scale = 1.0_sp / abs(norm_2(1)+abs(norm_2(2)) + abs(norm_2(3)))
  norm = norm_2 * scale

End Subroutine MOFZY

!===========================

Subroutine FindCentroid(angle, vof, cen_mof)
  Implicit None
  Integer, Parameter  :: sp = 8
  Real(sp), Intent(In) :: angle(2)
  Real(sp), Intent(In) :: vof
  Real(sp), Intent(Out) :: cen_mof(3)
  Real(sp) :: cen_sz(3)
  Real(sp) :: norm_2(3)
  Real(sp) :: norm_1(3)
  Real(sp) :: scale

  Call Angle2Norm(angle, norm_2)
  scale = 1.0_sp / (abs(norm_2(1))+abs(norm_2(2)) + abs(norm_2(3)))
  norm_1 = norm_2 * scale
  Call Volume_Centroid(norm_1,vof,cen_sz)
  cen_mof = cen_sz - 0.5_sp

End Subroutine FindCentroid

Subroutine Norm2Angle(angle, norm)
  Implicit None
  Integer, Parameter  :: sp = 8
  Real(sp), Intent(Out)  :: angle(2)
  Real(sp), Intent(In) :: norm(3)
  angle(2)=acos(norm(3))
  angle(1) = acos(norm(1) / sin(angle(2)) )
End Subroutine Norm2Angle

Subroutine Angle2Norm(angle, norm)
  Implicit None
  Integer, Parameter  :: sp = 8
  Real(sp), Intent(In)  :: angle(2)
  Real(sp), Intent(Out) :: norm(3)
  norm(3)=cos(angle(2))
  norm(1)=sin(angle(2))*cos(angle(1))
  norm(2)=sin(angle(2))*sin(angle(1))
End Subroutine Angle2Norm

subroutine advance_angle(angle,delangle)
  IMPLICIT NONE
  Integer, Parameter  :: sp = 8
  REAL(sp) angle,delangle

  angle=angle+delangle
  if (angle.lt.-MOF_Pi) then
    angle=angle+2.0_sp*MOF_Pi
  endif
  if (angle.gt.MOF_Pi) then
    angle=angle-2.0_sp*MOF_Pi
  endif

  return
end subroutine advance_angle

!=======================================================
! (4.1) Normalize the normal vector that satisfies
!    sigma norm(i) = 1
! and
!    all norm(i) > 0
!-------------------------------------------------------
! Input: norm (normal vector)
! Output: norm (normalized normal vector)
!=======================================================
Subroutine Normalization1(norm)
  Use ModGlobal, only : sp
  Implicit None
  Real(sp), Intent(Inout) :: norm(3)
  Real(sp), Intent(Out) :: abs_norm(3)
  Real(sp) :: aa

  abs_norm = abs(norm)
  aa = abs_norm(1) + abs_norm(2) + abs_norm(3)
  If( aa .gt. 1.d-10) Then
    norm = norm / aa
  End If
End Subroutine Normalization1

!=======================================================
! (4.2) Normalize the normal vector that is a unit vector
!     sigma norm(i)^2 = 1
!-------------------------------------------------------
! Input: norm (normal vector)
! Output: norm (normalized normal vector)
!=======================================================
Subroutine Normalization2(norm)
  Use ModGlobal, only : sp
  Implicit None
  Real(sp), Intent(Inout) :: norm(3)
  Real(sp) :: aa
  aa = Sqrt( norm(1) * norm(1) + &
      &      norm(2) * norm(2) + &
      &      norm(3) * norm(3) )
  If( aa .gt. 1.d-10) Then
    norm(1) = norm(1) / aa
    norm(2) = norm(2) / aa
    norm(3) = norm(3) / aa
  End If
End Subroutine Normalization2


End Module MOD_VOFFunc

