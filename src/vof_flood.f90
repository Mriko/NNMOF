!=======================================================
! Backward flooding algorithm of APPLIC.
! find alpha in
!    m1 x1 + m2 x2 + m3 x3 = alpha
!=======================================================
Real(sp) Function FloodAPPLIC_Backward(b1,b2,b3,cc) 
  Use ModGlobal, only : sp
  Implicit None
  Real(sp) :: m1,m2,m3,cc,b1,b2,b3,tmp,pr,ch,mm,m12
  Real(sp) :: UNTIER,V1,V2,V3
  Real(sp) :: alpha, w
  Real(sp) :: CONST_TINY,CONST_PI
  Real(sp) :: xi, invp, vma, vmb, vmc
  Real(sp), parameter :: ONE = 1.0d0, PB = 1.49d0,      &
  &   PC2 = 0.239d0, PC1 = 0.132_sp,                     &
  &   PC0 = (PB * (PB * PC2 + 4.0_sp * PC1 - 8.0_sp) / 16.0_sp), &
  &   PA = (PB * PB * (PB - 1.0_sp))

  PARAMETER (UNTIER=1.d0/3.d0)
  INTRINSIC DMAX1,DMIN1,DSQRT,DACOS,DCOS
  CONST_TINY = 1D-25
  CONST_PI = 3.14159265358979323846d0
  !***
  !     (1) order coefficients: m1<m2<m3; (2) get ranges: V1<V2<v3;
  !     (3) limit ch (0.d0 < ch < 0.5d0); (4) calculate alpha
  !*(1)*
  m1 = DMIN1(b1,b2)
  m3 = DMAX1(b1,b2)
  m2 = b3
  if (m2 .LT. m1) then
    tmp = m1
    m1 = m2
    m2 = tmp
  else if (m2 .GT. m3) then
    tmp = m3
    m3 = m2
    m2 = tmp
  endif
  !*(2)*
  m12 = m1 + m2 
  pr  = DMAX1(6.d0*m1*m2*m3,1.d-50)
  V1  = m1*m1*m1/pr
  V2  = V1 + 0.5d0*(m2-m1)/m3
  if (m3 .LT. m12) then
    mm = m3
    V3 = (m3*m3*(3.d0*m12-m3) + m1*m1*(m1-3.d0*m3) + &
    &        m2*m2*(m2-3.d0*m3))/pr
  else
    mm = m12
    V3 = 0.5d0*mm/m3
  endif

  !*(3)*
  ch = DMIN1(cc,1.d0-cc)

  !*(4)*
  ! Aoki APPLIC method
  vma = ABS(b1)
  vmb = ABS(b2)
  vmc = ABS(b3)

  w = min(cc, 1.0D0 - cc)
  xi = (PB - vma) * (PB - vmb) * (PB - vmc) - PA
  invp = (xi + PC0) / ((PC2 * xi + PC1) * xi + PC0)
  alpha = 0.5d0 * exp(log(w + w) * invp) 
  if (cc > 0.5d0) alpha = 1d0 - alpha 
  FloodAPPLIC_backward = alpha
  !
  return
end FUNCTION FloodAPPLIC_Backward

!=======================================================
! Forward flooding algorithm of APPLIC.
! FIND THE "CUT VOLUME" V0
! for GIVEN
!    r0, dr0
!  and
!    m1 x1 + m2 x2 + m3 x3 = alpha
!=======================================================
Real(sp) FUNCTION FloodAPPLIC_forward(m1,m2,m3,alpha,r0,dr0)
  Use ModGlobal, only : sp
  Implicit None
  Real(sp) :: p,m1,m2,m3,alpha,r0,dr0,a,v
  Real(sp) :: xi, vma, vmb, vmc
  Real(sp) :: al,al0,n1,n2,n3,b1,b2,b3,b12,bm,tmp,pr,CONST_TINY
  Real(sp), parameter :: ONE = 1.0d0, PB = 1.49d0,&
  &        PC2 = 0.239d0, PC1 = 0.132d0, &
  &        PC0 = (PB * (PB * PC2 + 4d0 * PC1 - 8d0) / 16d0), &
  &        PA = (PB * PB * (PB - 1d0)) 
  CONST_TINY = 1D-25
  !***
  !     (1) move origin to r0 along r ;  (2) reflect parallelepiped;
  !     (3) limit alpha (0<= al0 <=0.5); (4) order coefficients: b1<b2<b3;
  !     (5) calculate volume (NOTE: it is assumed:s0=t0=0; ds0=dt0=1.)

  !*(1)*
  al = alpha - m1*r0

  !*(2)*
  al = al + DMAX1(0.d0,-m1*dr0)+DMAX1(0.d0,-m2)+DMAX1(0.d0,-m3)
  tmp = DABS(m1)*dr0 + DABS(m2) + DABS(m3)
  n1 = DABS(m1)/tmp
  n2 = DABS(m2)/tmp
  n3 = DABS(m3)/tmp
  al = DMAX1(0.d0,DMIN1(1.d0,al/tmp))

  !*(3)*
  al0 = DMIN1(al,1.d0-al)

  !*(4)*
  b1 = DMIN1(n1*dr0,n2)
  b3 = DMAX1(n1*dr0,n2)
  b2 = n3
  if (b2 .LT. b1) then
    tmp = b1
    b1 = b2
    b2 = tmp
  else if (b2 .GT. b3) then
    tmp = b3
    b3 = b2
    b2 = tmp
  endif
  b12 = b1 + b2
  bm = DMIN1(b12,b3)
  pr = DMAX1(6.d0*b1*b2*b3,1.0d-50)

  ! Aoki APPLIC method
  vma = b1 !ABS(nr(1))
  vmb = b2 !ABS(nr(2))
  vmc = b3 !ABS(nr(3))
  a = min(al, 1d0 - al)
  v = 0d0
  if (a > 0d0) then
    xi = (PB - vma) * (PB - vmb) * (PB - vmc) - PA
    p = ((PC2 * xi + PC1) * xi + PC0) / (xi + PC0)
    v = 0.5d0 * exp(log(a + a) * p)
  end if
  tmp = v

  if (al .LE. 0.5d0) then
    FloodAPPLIC_forward = tmp*dr0
  else
    FloodAPPLIC_forward = (1.d0-tmp)*dr0
  endif
  return
end FUNCTION FloodAPPLIC_forward

!=======================================================
! Backward flooding algorithm of SZ.
! find alpha in
!    m1 x1 + m2 x2 + m3 x3 = alpha
!=======================================================
Real(sp) Function FloodSZ_Backward(b1,b2,b3,cc) 
  Use ModGlobal, only : sp
  Implicit None
  Real(sp) :: m1,m2,m3,cc,b1,b2,b3,tmp,pr,ch,mm,m12
  Real(sp) :: p,p12,q,teta,cs
  Real(sp) :: UNTIER,V1,V2,V3
  Real(sp) :: CONST_TINY,CONST_PI, alpha
  Real(sp), parameter :: ONE = 1.0d0, PB = 1.49d0,      &
  &   PC2 = 0.239d0, PC1 = 0.132_sp,                     &
  &   PC0 = (PB * (PB * PC2 + 4.0_sp * PC1 - 8.0_sp) / 16.0_sp), &
  &   PA = (PB * PB * (PB - 1.0_sp))

  PARAMETER (UNTIER=1.d0/3.d0)
  INTRINSIC DMAX1,DMIN1,DSQRT,DACOS,DCOS
  CONST_TINY = 1D-25
  CONST_PI = 3.14159265358979323846d0
  !***
  !     (1) order coefficients: m1<m2<m3; (2) get ranges: V1<V2<v3;
  !     (3) limit ch (0.d0 < ch < 0.5d0); (4) calculate alpha
  !*(1)*
  m1 = DMIN1(b1,b2)
  m3 = DMAX1(b1,b2)
  m2 = b3
  if (m2 .LT. m1) then
    tmp = m1
    m1 = m2
    m2 = tmp
  else if (m2 .GT. m3) then
    tmp = m3
    m3 = m2
    m2 = tmp
  endif
  !*(2)*
  m12 = m1 + m2 
  pr  = DMAX1(6.d0*m1*m2*m3,1.d-50)
  V1  = m1*m1*m1/pr
  V2  = V1 + 0.5d0*(m2-m1)/m3
  if (m3 .LT. m12) then
    mm = m3
    V3 = (m3*m3*(3.d0*m12-m3) + m1*m1*(m1-3.d0*m3) + &
    &        m2*m2*(m2-3.d0*m3))/pr
  else
    mm = m12
    V3 = 0.5d0*mm/m3
  endif

  !*(3)*
  ch = DMIN1(cc,1.d0-cc)

  !*(4)*
  ! SZ method      
  if (ch .LT. V1) then
    !***         AL3D = cbrt(pr*ch)
    alpha = (pr*ch)**UNTIER
  else if (ch .LT. V2) then
    alpha = 0.5d0*(m1 + DSQRT(m1*m1 + 8.d0*m2*m3*(ch-V1)))
  else if (ch .LT. V3) then
    p = 2.d0*m1*m2
    q = 1.5d0*m1*m2*(m12 - 2.d0*m3*ch)
    p12 = DSQRT(p)
    teta = DACOS(q/(p*p12))/3.d0
    cs = DCOS(teta)
    alpha = p12*(DSQRT(3.d0*(1.d0-cs*cs)) - cs) + m12
  else if (m12 .LT. m3) then
    alpha = m3*ch + 0.5d0*mm
  else 
    p = m1*(m2+m3) + m2*m3 - 0.25d0
    q = 1.5d0*m1*m2*m3*(0.5d0-ch)
    p12 = DSQRT(p)
    teta = DACOS(q/(p*p12))/3.0
    cs = DCOS(teta)
    alpha = p12*(DSQRT(3.d0*(1.d0-cs*cs)) - cs) + 0.5d0
  endif

  if (cc .GT. 0.5d0)  alpha = 1.d0 - alpha
  FloodSZ_backward = alpha
  return
end FUNCTION FloodSZ_Backward

!=======================================================
! Forward flooding algorithm of APPLIC.
! FIND THE "CUT VOLUME" V0
! for GIVEN
!    r0, dr0
!  and
!    m1 x1 + m2 x2 + m3 x3 = alpha
!=======================================================
Real(sp) FUNCTION FloodSZ_forward(m1,m2,m3,alpha,r0,dr0)
  Use ModGlobal, only : sp
  Implicit None
  Real(sp) :: m1,m2,m3,alpha,r0,dr0, vm1,vm2,vm3,vm12,a,v
  Real(sp) :: al,al0,n1,n2,n3,b1,b2,b3,b12,bm,tmp,pr,CONST_TINY
  Real(sp), parameter :: ONE = 1.0d0, PB = 1.49d0,&
  &        PC2 = 0.239d0, PC1 = 0.132d0, &
  &        PC0 = (PB * (PB * PC2 + 4d0 * PC1 - 8d0) / 16d0), &
  &        PA = (PB * PB * (PB - 1d0)) 
  CONST_TINY = 1D-25
  !***
  !     (1) move origin to r0 along r ;  (2) reflect parallelepiped;
  !     (3) limit alpha (0<= al0 <=0.5); (4) order coefficients: b1<b2<b3;
  !     (5) calculate volume (NOTE: it is assumed:s0=t0=0; ds0=dt0=1.)

  !*(1)*
  al = alpha - m1*r0

  !*(2)*
  al = al + DMAX1(0.d0,-m1*dr0)+DMAX1(0.d0,-m2)+DMAX1(0.d0,-m3)
  tmp = DABS(m1)*dr0 + DABS(m2) + DABS(m3)
  n1 = DABS(m1)/tmp
  n2 = DABS(m2)/tmp
  n3 = DABS(m3)/tmp
  al = DMAX1(0.d0,DMIN1(1.d0,al/tmp))

  !*(3)*
  al0 = DMIN1(al,1.d0-al)

  !*(4)*
  b1 = DMIN1(n1*dr0,n2)
  b3 = DMAX1(n1*dr0,n2)
  b2 = n3
  if (b2 .LT. b1) then
    tmp = b1
    b1 = b2
    b2 = tmp
  else if (b2 .GT. b3) then
    tmp = b3
    b3 = b2
    b2 = tmp
  endif
  b12 = b1 + b2
  bm = DMIN1(b12,b3)
  pr = DMAX1(6.d0*b1*b2*b3,1.0d-50)

  vm1 = b1 !min(vma, vmb, vmc) ! Sort vm1, vm2, vm3
  vm3 = b3 !max(vma, vmb, vmc) ! such that vm1 ¡Ü vm2 ¡Ü vm3 .
  vm2 = b2 !abs(1d0 - vm3 - vm1)
  vm12 = b12 !vm1 + vm2
  a = al0
  v = 0d0
  if (a > 0.0d0) then
    if (a < vm1) then
      v = a ** 3 / (6d0 * vm1 * vm2 * vm3)
    else if (a < vm2) then
      v = a * (a - vm1) / (2d0 * vm2 * vm3) + &
      &              vm1 ** 2 / (6d0 * vm2 * vm3 + CONST_TINY)
    else if (a < min(vm12, vm3)) then
      v = (a ** 2 * (3d0 * vm12 - a) + &
      &              vm1 ** 2 * (vm1 - 3d0 * a) + &
      &              vm2 ** 2 * (vm2 - 3d0 * a)) / &
      &              (6d0 * vm1 * vm2 * vm3)
    else if (vm3 < vm12) then 
      v = (a ** 2 * (3d0 - 2d0 * a) + &
      &              vm1 ** 2 * (vm1 - 3d0 * a) + &
      &              vm2 ** 2 * (vm2 - 3d0 * a) + &
      &              vm3 ** 2 * (vm3 - 3d0 * a)) / &
     &              (6d0 * vm1 * vm2 * vm3)
   else
     v = (a - 0.5d0 * vm12) / vm3
   end if
 endif
 tmp = v

 if (al .LE. 0.5d0) then
   FloodSZ_forward = tmp*dr0
 else
   FloodSZ_forward = (1.d0-tmp)*dr0
 endif

  return
end FUNCTION FloodSZ_forward
