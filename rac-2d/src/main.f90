program main

use configure
use disk
use my_timer
use trivials
use phy_const
use ray_tracing
use cdms
use binary_array_io
use spline_1d_2d

implicit none

integer i, j

type(atimer) timer
type(date_time) a_date_time

!!! TEST REGION
!type(type_table_2d) :: res
!type(type_spline_2D) :: spl
!double precision :: x0, y0
!call read_binary_array('/Users/fdu/Fe+_LUT.bin', res)
!write(*,*) res%nx, res%ny
!do i=1, res%nx
!  write(*,*) i, res%x(i)
!end do
!do i=1, res%ny
!  write(*,*) i, res%y(i)
!end do
!do i=1,5
!  do j=1,5
!    write(*,*) i, j, res%val(j,i)
!  end do
!end do
!x0 = dble(2.4898e+00) 
!y0 = dble(4.0156e+00)
!call get_idx_in_table(i, j, x0, y0, res, .true.)
!write(*, *) i, j
!write(*, *) res%x(i), res%y(j), res%val(i,j)
!!
!call create_spline2d_from_table(res, spl)
!write(*,*) spline2d_interpol(x0, y0, spl)
!call error_stop()
!!! END OF TEST REGION

call get_command_argument(0, a_disk_iter_params%filename_exe, i, j) ! feeds arguments on the command line
call get_command_argument(1, filename_config, i, j)
if (i .EQ. 0) then
  filename_config = 'configure.dat'
end if

call config_do ! from config.f90, reads input from .dat file and creates logs/backups

call timer%init('Main') ! initialize timer for iteration

call disk_iteration

if (a_disk_iter_params%redo_something) then
  !call do_rerun_single_points
  call do_save_only_structure
  call error_stop()
end if

#ifdef DO_RAY_TRACING
    call post_disk_iteration ! All the leaf nodes are associated to c (what does this mean?)
    !
    if (a_disk_iter_params%do_continuum_transfer) then
      call continuum_tran_prep
      !
      if (len_trim(raytracing_conf%dir_save_image) .eq. 0) then
        raytracing_conf%dir_save_image = a_disk_iter_params%iter_files_dir
      end if
      write(*, '(/A)') 'Doing continuum radiative transfer...'
      call make_cubes_continuum
    end if
    !
    if (a_disk_iter_params%do_line_transfer) then
      !
      dir_name_log = a_book_keeping%dir
      call line_tran_prep
      !
      if (raytracing_conf%VeloKepler .le. 0D0) then
        raytracing_conf%VeloKepler = sqrt( &
          phy_GravitationConst_SI * a_disk%star_mass_in_Msun * phy_Msun_SI / &
            (sqrt(root%xmin) * phy_AU2m))
      end if
      if (raytracing_conf%VeloTurb .le. 0D0) then
        raytracing_conf%VeloTurb = sqrt(phy_kBoltzmann_SI*1D2 / phy_mProton_SI)
      end if
      if (raytracing_conf%VeloWidth .le. 0D0) then
        raytracing_conf%VeloWidth = raytracing_conf%VeloTurb
      end if
      !
      if (len_trim(raytracing_conf%dir_save_image) .eq. 0) then
        raytracing_conf%dir_save_image = a_disk_iter_params%iter_files_dir
      end if
      !
      call line_excitation_do
      !
      write(*, '(/A)') 'Doing line radiative transfer...'
      call make_cubes_line
    end if
#endif
!
if (FileUnitOpened(a_book_keeping%fU)) then
  write(a_book_keeping%fU, '(A)') '! Current time: ' // &
    trim(a_date_time%date_time_str())
  close(a_book_keeping%fU)
end if

write(*, '(A)') 'Current time: ' // trim(a_date_time%date_time_str())
call timer%elapse

end program main
