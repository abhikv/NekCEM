c-----------------------------------------------------------------------
      subroutine get_dxmin (dxmin)
c
c     Compute dxmin over domain
c
      include 'SIZE'
      include 'GEOM'
      include 'INPUT'
      real     dxmin
      integer  e,ip,i,j,k

      d2m = 1.e20

      if (ldim.eq.3) then
         do e=1,nelv
         do k=2,nz1-1
         do j=2,ny1-1
         do i=2,nx1-1

            km=k-1
            kp=k+1
            jm=j-1
            jp=j+1
            im=i-1
            ip=i+1

            dx = xm1(ip,j,k,e) - xm1(im,j,k,e)
            dy = ym1(ip,j,k,e) - ym1(im,j,k,e)
            dz = zm1(ip,j,k,e) - zm1(im,j,k,e)
            d2 = dx*dx + dy*dy + dz*dz
            d2m = min(d2m,d2)

            dx = xm1(i,jp,k,e) - xm1(i,jm,k,e)
            dy = ym1(i,jp,k,e) - ym1(i,jm,k,e)
            dz = zm1(i,jp,k,e) - zm1(i,jm,k,e)
            d2 = dx*dx + dy*dy + dz*dz
            d2m = min(d2m,d2)

            dx = xm1(i,j,kp,e) - xm1(i,j,km,e)
            dy = ym1(i,j,kp,e) - ym1(i,j,km,e)
            dz = zm1(i,j,kp,e) - zm1(i,j,km,e)
            d2 = dx*dx + dy*dy + dz*dz
            d2m = min(d2m,d2)

         enddo
         enddo
         enddo
         enddo

      else  ! 2D
         do e=1,nelv
         do j=2,ny1-1
         do i=2,nx1-1

            jm=j-1
            jp=j+1
            im=i-1
            ip=i+1

            dx = xm1(ip,j,1,e) - xm1(im,j,1,e)
            dy = ym1(ip,j,1,e) - ym1(im,j,1,e)
            d2 = dx*dx + dy*dy
            d2m = min(d2m,d2)

            dx = xm1(i,jp,1,e) - xm1(i,jm,1,e)
            dy = ym1(i,jp,1,e) - ym1(i,jm,1,e)
            d2 = dx*dx + dy*dy
            d2m = min(d2m,d2)

         enddo
         enddo
         enddo
      endif

      dxmin = sqrt(d2m)/2.
      dxmin = glmin(dxmin,1)

      return
      end
c-----------------------------------------------------------------------
