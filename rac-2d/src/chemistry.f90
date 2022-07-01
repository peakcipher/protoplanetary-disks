module chemistry

use trivials
use phy_const
use data_struct


implicit none


integer, parameter, public    :: const_len_species_name       = 12
integer, parameter, private   :: const_len_reactionfile_row   = 150
integer, parameter, public    :: const_len_init_abun_file_row = 64
integer, parameter, private   :: const_nSpecies_guess         = 1024
integer, parameter, private   :: const_n_dupli_max_guess      = 8
integer, parameter, private   :: const_n_reac_max             = 3
integer, parameter, private   :: const_n_prod_max             = 4
character, parameter, private :: const_grainSpe_prefix        = 'g'
!
integer, parameter, public :: const_nElement               = 20
character(LEN=8), dimension(const_nElement), parameter :: &
  const_nameElements = &
    (/'+-      ', 'E       ', 'Grain   ', 'H       ', &
      'D       ', 'He      ', 'C       ', 'N       ', &
      'O       ', 'Si      ', 'S       ', 'Fe      ', &
      'Na      ', 'Mg      ', 'Cl      ', 'P       ', &
      'F       ', 'Ne      ', 'Ar      ', 'K       '/)
double precision, dimension(const_nElement), parameter :: &
  const_ElementMassNumber = &
    (/0D0,        5.45D-4,    0D0,        1D0,        &
      2D0,        4D0,        12D0,       14D0,       &
      16D0,       28D0,       32D0,       56D0,       &
      23D0,       24D0,       35.5D0,     31D0,       &
      19D0,       20.18D0,    39.95D0,    39.1D0/)


type :: type_chemical_evol_idx_species
  integer i_H2, i_HI, i_E, i_CI, i_CII, i_NI, i_OI, i_O2, i_CO, i_H2O, &
          i_OH, i_Hplus, i_gH, i_gH2, i_Heplus, i_NII, i_SiII, i_FeII
  integer iiH2, iiHI, iiE, iiCI, iiCII, iiOI, iiO2, iiCO, iiH2O, &
          iiOH
  integer i_Grain0, i_GrainM, i_GrainP, i_gH2O, i_gCO, i_gCO2, i_gN2
  integer :: nItem = 10
  integer, dimension(:), allocatable :: idx
  character(len=8), dimension(10) :: names = &
    (/'H2      ', 'H       ', 'E-      ', 'C       ', 'C+      ', &
      'O       ', 'O2      ', 'CO      ', 'H2O     ', 'OH      '/)
end type type_chemical_evol_idx_species


type :: type_chemical_evol_reactions_str
  integer nReactions
  character :: commentChar = '!'
  character(len=const_len_reactionfile_row), dimension(:), allocatable :: list
end type type_chemical_evol_reactions_str


type :: type_chemical_evol_a_list
  integer nItem
  integer, dimension(:), allocatable :: list
end type type_chemical_evol_a_list


type :: type_chemical_evol_a_list_big
  integer nItem
  integer, dimension(:), allocatable :: list
  integer, dimension(:), allocatable :: n_repeat
  double precision, dimension(:), allocatable :: contri
end type type_chemical_evol_a_list_big


type :: type_chemical_evol_reactions
  integer nReactions, nReacWithHeat
  character(len=const_len_species_name), dimension(:,:), &
    allocatable :: reac_names, prod_names
  integer, dimension(:,:), allocatable :: reac, prod
  integer, dimension(:), allocatable :: n_reac, n_prod
  double precision, dimension(:,:), allocatable :: ABC
  double precision, dimension(:,:), allocatable :: T_range
  integer, dimension(:), allocatable :: itype
  character(len=2), dimension(:), allocatable :: ctype
  character, dimension(:), allocatable :: reliability
  double precision, dimension(:), allocatable :: rates
  double precision, dimension(:), allocatable :: heat
  type(type_chemical_evol_a_list), dimension(:), allocatable :: dupli
  integer, dimension(:), allocatable :: iReacWithHeat
end type type_chemical_evol_reactions


type :: type_chemical_evol_species
  integer nSpecies, nGrainSpecies
  character(len=const_len_species_name), dimension(:), allocatable :: names
  double precision, dimension(:), allocatable :: mass_num
  double precision, dimension(:), allocatable :: vib_freq
  double precision, dimension(:), allocatable :: Edesorb
  double precision, dimension(:), allocatable :: adsorb_coeff
  double precision, dimension(:), allocatable :: desorb_coeff
  double precision, dimension(:), allocatable :: enthalpies
  logical, dimension(:), allocatable :: hasEnthalpy
  integer, dimension(:), allocatable :: idx_gasgrain_counterpart
  integer, dimension(:,:), allocatable :: elements
  type(type_chemical_evol_a_list_big), dimension(:), allocatable :: produ, destr
  integer, dimension(:), allocatable :: idxGrainSpecies
end type type_chemical_evol_species


type :: type_chemical_evol_solver_params
  character(len=128) chem_files_dir, &
    filename_chemical_network, &
    filename_initial_abundances, &
    filename_species_enthalpy
  double precision :: RTOL, ATOL
  double precision :: t0=0D0, t_max=1D6, t_max0=1D6, &
    dt_first_step=1D-6, dt_first_step0, ratio_tstep, t_scale_tol
  logical H2_form_use_moeq
  real :: max_runtime_allowed = 3600.0 ! seconds
  integer :: mxstep_per_interval = 2000
  integer n_record, n_record_real
  integer NEQ, ITOL, ITASK, ISTATE, IOPT, LIW, LRW, MF, NNZ
  integer NERR
  integer quality
  character(len=128) :: chem_evol_save_filename = 'chem_evol_tmp.dat'
  logical :: flag_chem_evol_save = .false.
  logical evolT, maySwitchT
  logical :: evol_dust_size = .false.
  double precision :: Diff2DesorRatio = 0.5D0
  double precision :: Edesorb_gH_bare_grain        = 1.0D4
  double precision :: Edesorb_gH_icy_grain         = 450D0
  double precision :: special_gH_E_diff            = 225D0
  logical :: update_gH_params_realtime = .false.
  logical :: use_special_gH_mobi = .false.
  integer :: steps_Update_gH_params = 5
  integer :: steps_reset_solver = 9999999
  integer fU_log
end type type_chemical_evol_solver_params


type :: type_chemical_evol_solver_storage
  double precision, dimension(:), allocatable :: RWORK
  integer, dimension(:), allocatable :: IWORK
  logical, dimension(:, :), allocatable :: sparseMaskJac
  double precision, dimension(:), allocatable :: y, y0
  double precision, dimension(:), allocatable :: ydot
  double precision, dimension(:), allocatable :: touts
  double precision, dimension(:, :), allocatable :: record
  double precision, dimension(:), allocatable :: RTOLs, ATOLs
end type type_chemical_evol_solver_storage


type :: type_elemental_residence
  integer ielement
  double precision, dimension(:), allocatable :: ele_frac, ele_accu
  integer, dimension(:), allocatable :: iSpecies
  integer n_nonzero
end type type_elemental_residence


type(type_chemical_evol_reactions_str)  :: chem_reac_str

type(type_chemical_evol_idx_species)    :: chem_idx_some_spe

type(type_chemical_evol_reactions)      :: chem_net

type(type_chemical_evol_species)        :: chem_species

type(type_chemical_evol_solver_params)  :: chemsol_params
type(type_chemical_evol_solver_storage) :: chemsol_stor

! This thing is specific to each cell.
type(type_cell_rz_phy_basic), target :: chem_params


type(type_elemental_residence), dimension(:), allocatable :: chem_ele_resi

integer, parameter :: chem_ele_resi_nmax = 10
double precision, parameter :: chem_ele_frac_threshold_to_sum = 0.999D0
double precision, parameter :: chem_ele_frac_threshold_to_max = 1D-5

double precision, parameter :: const_cosmicRay_intensity_0 = 1.36D-17 ! UMIST paper
double precision, parameter :: CosmicDesorpPreFactor = 3.16D-19
double precision, parameter :: CosmicDesorpGrainT = 70D0

namelist /chemistry_configure/ &
  chemsol_params


contains

! To set the parameters mentioned in the code.
subroutine chem_set_solver_flags
  chemsol_params%IOPT = 1 ! 1: allow optional input; 0: disallow
  chemsol_params%NERR = 0 ! for counting number of errors in iteration
  chemsol_params%ITOL = 4
  chemsol_params%ITASK = 4
  chemsol_params%ISTATE = 1 ! first call
  chemsol_params%MF = 021 ! Line 2557 of opkdmain.f
  chemsol_stor%RTOLs = chemsol_params%RTOL
  chemsol_stor%ATOLs = chemsol_params%ATOL
  chemsol_stor%RTOLs(chem_species%nSpecies+1) = 1D-3
  chemsol_stor%ATOLs(chem_species%nSpecies+1) = 1D-1
  chemsol_params%t_scale_tol = 1D-10
end subroutine chem_set_solver_flags

! To set the parameters mentioned in the code.
subroutine chem_set_solver_flags_alt(j)
  integer, intent(in) :: j
  chemsol_params%IOPT = 1 ! 1: allow optional input; 0: disallow
  chemsol_params%ITOL = 4
  chemsol_params%ITASK = 4
  chemsol_params%ISTATE = 1 ! first call
  chemsol_params%MF = 021 ! Line 2557 of opkdmain.f
  !
  ! For generic species
  select case(j)
  case(1)
    chemsol_stor%RTOLs = chemsol_params%RTOL
    chemsol_stor%ATOLs = chemsol_params%ATOL
    chemsol_stor%RTOLs(chem_species%nSpecies+1) = 1D-3
    chemsol_stor%ATOLs(chem_species%nSpecies+1) = 1D-1
    chemsol_params%t_scale_tol = 1D-6
  case(2)
    chemsol_stor%RTOLs = min(chemsol_params%RTOL * 1D1, 1D-4)
    chemsol_stor%ATOLs = min(chemsol_params%ATOL * 1D5, 1D-25)
    chemsol_stor%RTOLs(chem_species%nSpecies+1) = 1D-2
    chemsol_stor%ATOLs(chem_species%nSpecies+1) = 1D-1
    chemsol_params%t_scale_tol = 1D-4
  case(3)
    chemsol_stor%RTOLs = min(chemsol_params%RTOL * 1D2, 1D-4)
    chemsol_stor%ATOLs = min(chemsol_params%ATOL * 1D10, 1D-20)
    chemsol_stor%RTOLs(chem_species%nSpecies+1) = 1D-3
    chemsol_stor%ATOLs(chem_species%nSpecies+1) = 1D0
    chemsol_params%t_scale_tol = 1D-3
  case(4)
    chemsol_stor%RTOLs = min(chemsol_params%RTOL * 1D2, 1D-4)
    chemsol_stor%ATOLs = min(chemsol_params%ATOL * 1D10, 1D-18)
    chemsol_stor%RTOLs(chem_species%nSpecies+1) = 1D-3
    chemsol_stor%ATOLs(chem_species%nSpecies+1) = 1D0
    chemsol_params%t_scale_tol = 1D-2
  case default
    chemsol_stor%RTOLs = min(chemsol_params%RTOL * 2D0**j, 1D-3)
    chemsol_stor%ATOLs = min(chemsol_params%ATOL * 1D2**j, 1D-15)
    chemsol_stor%RTOLs(chem_species%nSpecies+1) = 1D-2
    chemsol_stor%ATOLs(chem_species%nSpecies+1) = 1D0
    chemsol_params%t_scale_tol = 1D-1
  end select
  ! For species that are used for heating and cooling
  chemsol_stor%RTOLs(chem_idx_some_spe%idx) = max(chemsol_params%RTOL, 1D-4)
  chemsol_stor%ATOLs(chem_idx_some_spe%idx) = max(chemsol_params%ATOL, 1D-30)
  ! For Grain0, Grain+, Grain-
  if (chem_idx_some_spe%i_Grain0 .gt. 0) then
    chemsol_stor%RTOLs(chem_idx_some_spe%i_Grain0) = 1D-4
    chemsol_stor%ATOLs(chem_idx_some_spe%i_Grain0) = &
        max(chem_params%ratioDust2HnucNum*1D-6, 1D-30)
    chemsol_stor%RTOLs(chem_idx_some_spe%i_GrainM) = 1D-4
    chemsol_stor%ATOLs(chem_idx_some_spe%i_GrainM) = &
        max(chem_params%ratioDust2HnucNum*1D-6, 1D-30)
    chemsol_stor%RTOLs(chem_idx_some_spe%i_GrainP) = 1D-4
    chemsol_stor%ATOLs(chem_idx_some_spe%i_GrainP) = &
        max(chem_params%ratioDust2HnucNum*1D-6, 1D-30)
  end if
  ! For surface species
  if (chem_species%nGrainSpecies .gt. 0) then
    chemsol_stor%RTOLs(chem_species%idxGrainSpecies) = &
      max(chemsol_params%RTOL, 1D-3)
    chemsol_stor%ATOLs(chem_species%idxGrainSpecies) = &
      max(chemsol_params%ATOL, chem_params%ratioDust2HnucNum*1D-8)
  end if
end subroutine chem_set_solver_flags_alt


! Setting the outputs for different types of errors
! and finding the cause.
subroutine ode_solver_error_handling
  character(len=128) str_disp
  integer idx
  write(str_disp, '(A, I4)') '!Error: ', chemsol_params%ISTATE
  call display_string_both(str_disp, chemsol_params%fU_log)
  select case (chemsol_params%ISTATE)
    case (-1)
      ! Do nothing
    case (-2)
      write(str_disp, '(A)') '!Error: Excess accuracy requested.'
      call display_string_both(str_disp, chemsol_params%fU_log)
      !
      !chemsol_stor%RTOLs(1:chem_species%nSpecies) = &
      !  min(chemsol_stor%RTOLs(1) * 10D0, 1D-6)
      !chemsol_stor%ATOLs(1:chem_species%nSpecies) = &
      !  min(chemsol_stor%ATOLs(1) * 10D0, 1D-30)
      !
      write(str_disp, '(A, 2ES16.6)') '!Degrading RTOL and ATOL to ', &
        chemsol_stor%RTOLs(1), chemsol_stor%ATOLs(1)
      call display_string_both(str_disp, chemsol_params%fU_log)
    case (-3)
      write(str_disp, '(A)') '!Error: Illegal input.'
      call display_string_both(str_disp, chemsol_params%fU_log)
      write(str_disp, '(A)') '!Will give up the current run.'
      call display_string_both(str_disp, chemsol_params%fU_log)
    case (-4)
      write(str_disp, '(A)') '!Error: Repeated error test failures.'
      call display_string_both(str_disp, chemsol_params%fU_log)
      if (chemsol_stor%IWORK(16) .le. chem_species%nSpecies) then
        write(str_disp, '(A, I4, X, A12, A)') &
          '!', chemsol_stor%IWORK(16), &
          chem_species%names(chemsol_stor%IWORK(16)), ' is causing problem.'
        call display_string_both(str_disp, chemsol_params%fU_log)
        idx = chemsol_stor%IWORK(17) - chemsol_params%NEQ + chemsol_stor%IWORK(16)
        write(str_disp, '(A, 4ES16.6)') &
          '!val, rtol, atol, err=', &
          chemsol_stor%y(chemsol_stor%IWORK(16)), &
          chemsol_stor%RTOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%ATOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%RWORK(idx)
        call display_string_both(str_disp, chemsol_params%fU_log)
      else
        write(str_disp, '(A, I4, X, A)') &
          '!', chemsol_stor%IWORK(16), 'T is causing problem.'
        call display_string_both(str_disp, chemsol_params%fU_log)
        idx = chemsol_stor%IWORK(17) - chemsol_params%NEQ + chemsol_stor%IWORK(16)
        write(str_disp, '(A, 4ES16.6)') '!val, rtol, atol, err=', &
          chemsol_stor%y(chemsol_stor%IWORK(16)), &
          chemsol_stor%RTOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%ATOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%RWORK(idx)
        call display_string_both(str_disp, chemsol_params%fU_log)
      end if
      !
      idx = chemsol_stor%IWORK(16)
      if (idx .le. chem_species%nSpecies) then
        chemsol_stor%RTOLs(idx) = &
          min(chemsol_stor%RTOLs(idx) * 10D0, 1D-3)
        chemsol_stor%ATOLs(idx) = &
          min(chemsol_stor%ATOLs(idx) * 100D0, 1D-20)
      else
        chemsol_stor%RTOLs(idx) = &
          min(chemsol_stor%RTOLs(idx) * 10D0, 1D-2)
        chemsol_stor%ATOLs(idx) = &
          min(chemsol_stor%ATOLs(idx) * 100D0, 1D0)
      end if
    case (-5)
      write(str_disp, '(A)') '!Error: Repeated convergence test failures.'
      call display_string_both(str_disp, chemsol_params%fU_log)
      if (chemsol_stor%IWORK(16) .le. chem_species%nSpecies) then
        write(str_disp, '(A, I4, X, A12, A)') &
          '!', chemsol_stor%IWORK(16), &
          chem_species%names(chemsol_stor%IWORK(16)), ' is causing problem.'
        call display_string_both(str_disp, chemsol_params%fU_log)
        idx = chemsol_stor%IWORK(17) - chemsol_params%NEQ + chemsol_stor%IWORK(16)
        write(str_disp,'(A, 4ES16.6)') '!val, rtol, atol, err=', &
          chemsol_stor%y(chemsol_stor%IWORK(16)), &
          chemsol_stor%RTOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%ATOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%RWORK(idx)
        call display_string_both(str_disp, chemsol_params%fU_log)
      else
        write(str_disp, '(A, I4, X, A)') &
          '!', chemsol_stor%IWORK(16), 'T is causing problem.'
        call display_string_both(str_disp, chemsol_params%fU_log)
        idx = chemsol_stor%IWORK(17) - chemsol_params%NEQ + chemsol_stor%IWORK(16)
        write(str_disp,'(A, 4ES16.6)') '!val, rtol, atol, err=', &
          chemsol_stor%y(chemsol_stor%IWORK(16)), &
          chemsol_stor%RTOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%ATOLs(chemsol_stor%IWORK(16)), &
          chemsol_stor%RWORK(idx)
        call display_string_both(str_disp, chemsol_params%fU_log)
      end if
      !
      idx = chemsol_stor%IWORK(16)
      if (idx .le. chem_species%nSpecies) then
        chemsol_stor%RTOLs(idx) = &
          min(chemsol_stor%RTOLs(idx) * 10D0, 1D-3)
        chemsol_stor%ATOLs(idx) = &
          min(chemsol_stor%ATOLs(idx) * 100D0, 1D-20)
      else
        chemsol_stor%RTOLs(idx) = &
          min(chemsol_stor%RTOLs(idx) * 10D0, 1D-2)
        chemsol_stor%ATOLs(idx) = &
          min(chemsol_stor%ATOLs(idx) * 100D0, 1D0)
      end if
    case (-6)
      write(str_disp, '(A)') '!Error: Something becomes zero with atol=0.'
      call display_string_both(str_disp, chemsol_params%fU_log)
    case (-7)
      write(str_disp, '(A)') '!Error: Sparse solver error.'
      call display_string_both(str_disp, chemsol_params%fU_log)
      call error_stop()
  end select
  write(*,*)
end subroutine ode_solver_error_handling


! This subroutine evolves the disk chemistry and mainly
! controls the time spent per step and hence the total runtime.
subroutine chem_evol_solve
  use my_timer
  external chem_ode_f, chem_ode_jac
  integer i, j
  double precision t, tout, t_step
  type(atimer) timer
  real time_thisstep, runtime_thisstep, time_laststep, runtime_laststep
  double precision T1, T2, dt, max_time_per_step
  integer nTHistCheck, nerr_c
  !--
  character(len=32) fmtstr
  integer fU_chem_evol_save
  !
  if (chemsol_params%flag_chem_evol_save) then
    call openFileSequentialWrite(fU_chem_evol_save, &
         chemsol_params%chem_evol_save_filename, 99999, getu=1)
    write(fmtstr, '("(", I4, "A14)")') chem_species%nSpecies+2
    write(fU_chem_evol_save, fmtstr) &
      '! Time        ', &
      chem_species%names(1:chem_species%nSpecies), &
      '   Tgas       '
    write(fmtstr, '("(", I4, "ES14.4E4)")') chem_species%nSpecies+2
  end if
  !--
  !
  nTHistCheck = 5
  nerr_c = 0
  !
  t = chemsol_params%t0
  t_step = chemsol_params%dt_first_step
  tout = t + t_step
  chemsol_stor%touts(1) = t
  chemsol_stor%record(:,1) = chemsol_stor%y
  !
  chemsol_stor%RWORK(1) = chemsol_params%t_max
  chemsol_stor%RWORK(6) = chemsol_params%t_max
  !
  call timer%init('Chem')
  time_laststep = timer%elapsed_time()
  runtime_laststep = huge(0.0)
  !
  chemsol_params%NERR = 0 ! for counting number of errors in iteration
  chemsol_params%quality = 0
  !
  !call get_elemental_abundance(chemsol_stor%y, chemsol_params%NEQ, &
  !  ele_bef, const_nElement)
  !
  max_time_per_step = 5D0/dble(chemsol_params%n_record) * chemsol_params%max_runtime_allowed
  !
  do i=2, chemsol_params%n_record
    !
    if (tout .ge. chemsol_params%t_max) then
      chemsol_params%ITASK = 4
      tout = chemsol_params%t_max
    else
      chemsol_params%ITASK = 4
    end if
    !
    call DLSODES( &
         chem_ode_f, &
         !
         chemsol_params%NEQ, &
         chemsol_stor%y(1:chemsol_params%NEQ), &
         !
         t, &
         tout, &
         !
         chemsol_params%ITOL, &
         chemsol_stor%RTOLs, &
         chemsol_stor%ATOLs, &
         chemsol_params%ITASK, &
         chemsol_params%ISTATE, &
         chemsol_params%IOPT, &
         chemsol_stor%RWORK, &
         chemsol_params%LRW, &
         chemsol_stor%IWORK, &
         chemsol_params%LIW, &
         !
         chem_ode_jac, &
         !
         chemsol_params%MF)
    chemsol_stor%touts(i) = t
    chemsol_stor%record(:,i) = chemsol_stor%y
    chemsol_params%n_record_real = i
    !
    if (chemsol_params%flag_chem_evol_save) then
      write(fU_chem_evol_save, fmtstr) t, chemsol_stor%y
    end if
    !
    time_thisstep = timer%elapsed_time()
    runtime_thisstep = time_thisstep - time_laststep
    if ((runtime_thisstep .gt. max(10.0D0*runtime_laststep, &
                                   0.5D0*chemsol_params%max_runtime_allowed)) &
        .or. &
        (time_thisstep .gt. chemsol_params%max_runtime_allowed)) then
      write(*, '(A, ES9.2)') 'Premature finish: t = ', t
      exit
    end if
    if (runtime_thisstep .gt. max_time_per_step) then
      chemsol_params%ISTATE = 1
    end if
    !
    time_laststep = time_thisstep
    runtime_laststep = runtime_thisstep
    !
    if (t .ge. chemsol_params%t_max) then
      exit
    end if
    !
    if (chemsol_params%ISTATE .LT. 0) then
      chemsol_params%NERR = chemsol_params%NERR + 1
      nerr_c = nerr_c + 1
      call ode_solver_error_handling
      if (chemsol_params%ISTATE .eq. -3) then
        ! Illegal input is an uncorrectable error
        chemsol_params%quality = chemsol_params%quality + 256
        write(*, '(A, 3ES16.6, I6/)') 't,tout,tmax,qual:', &
          t, tout, chemsol_params%t_max, chemsol_params%quality
        exit
      else
        if (nerr_c .lt. 3) then
          chemsol_params%ISTATE = 3
        else
          chemsol_params%ISTATE = 1
          nerr_c = 0
        end if
      end if
    end if
    !
    if ((isnan(chemsol_stor%y(chemsol_params%NEQ))) .or. &
        (abs(chemsol_stor%y(chem_idx_some_spe%i_gH2)) .gt. 1D0) .or. &
        (abs(chemsol_stor%y(chem_idx_some_spe%i_gH2O)) .gt. 1D0) .or. &
        (abs(chemsol_stor%y(chem_idx_some_spe%i_gH)) .gt. 1D0) .or. &
        (abs(chemsol_stor%y(chem_idx_some_spe%i_HI)) .gt. 2D0) .or. &
        (abs(chemsol_stor%y(chem_idx_some_spe%i_E)) .gt. 1D0) .or. &
        (chemsol_stor%y(chemsol_params%NEQ) .le. 0D0)) then
      ! Horrible things
      chemsol_params%quality = chemsol_params%quality + 512
      exit
    end if
    !
    if (chemsol_params%maySwitchT .and. &
        chemsol_params%evolT .and. &
        (i .gt. nTHistCheck*2) .and. &
        (t .gt. 1D-2 * chemsol_params%t_max)) then
      T1 = maxval(chemsol_stor%record(chem_species%nSpecies+1, (i-nTHistCheck+1):i))
      T2 = minval(chemsol_stor%record(chem_species%nSpecies+1, (i-nTHistCheck+1):i))
      dt = chemsol_stor%touts(i) - chemsol_stor%touts(i-nTHistCheck)
      if ((T1 - T2) .lt. &
          chemsol_params%t_scale_tol*(T1+T2) * dt/chemsol_params%t_max) then
      !if (abs(T1 - T2) .le. chemsol_params%delT_switch * T2) then
        chemsol_params%ISTATE = 1
        chemsol_params%evolT = .false.
        write(*,'(A, ES16.6/)') 'Stop T evolving at t = ', t
      end if
    end if
    !
    write (*, '(A, 25X, "Solving chemistry... ", I5, " (", F5.1, "%)", &
              &"  t = ", ES9.2, "  tStep = ", ES9.2)') &
      CHAR(27)//'[A', i, real(i*100)/real(chemsol_params%n_record), t, t_step
    !
    ! The desorption energy (hence vibrational frequency) of hydrogen depends on
    ! the grain surface ice coverage.
    if ((chemsol_params%update_gH_params_realtime) .and. &
        (mod(i, chemsol_params%steps_Update_gH_params) .eq. 0)) then
      chemsol_params%ISTATE = 1
      call update_gH_params(chemsol_params%NEQ, &
             chemsol_stor%y(1:chemsol_params%NEQ))
      call chem_cal_rates
    end if
    if (mod(i, chemsol_params%steps_reset_solver) .eq. 0) then
      chemsol_params%ISTATE = 1
    end if
    !
    t_step = t_step * chemsol_params%ratio_tstep
    tout = t + t_step
    !
  end do
  !
  if (chemsol_params%n_record_real .lt. chemsol_params%n_record) then
    do i=chemsol_params%n_record_real+1, chemsol_params%n_record
      chemsol_stor%touts(i) = t
      chemsol_stor%record(:, i) = chemsol_stor%y
    end do
  end if
  !
  if (chemsol_params%NERR .gt. int(0.1*real(chemsol_params%n_record))) then
    chemsol_params%quality = chemsol_params%quality + 1
  end if
  if (t .le. (0.5D0 * chemsol_params%t_max)) then
    chemsol_params%quality = chemsol_params%quality + 2
  end if
  !
  if (chemsol_params%flag_chem_evol_save) then
    close(fU_chem_evol_save)
  end if
  !
end subroutine chem_evol_solve

! This subroutine calculates the chemical rate using various
! chemical parameters like gas temperature, radius of grain etc.
subroutine chem_cal_rates
  integer i, j, k, i1, i2
  double precision T300, TemperatureReduced, JNegaPosi, JChargeNeut
  double precision, dimension(4) :: tmpVecReal
  integer, dimension(1) :: tmpVecInt
  double precision tmp, natom_ongrain
  integer charge1, charge2, charge3, id1, id2, id3
  double precision m, sig_dust, cosmicray_rela, Xray_rela
  double precision stickCoeff, photoyield
  double precision f_H2_cov_modi, Edesorb_eff, branchingratio
  double precision, parameter :: grain_atom_sep_CGS = 1D-8
  !
  T300 = chem_params%Tgas / 300D0
  TemperatureReduced = phy_kBoltzmann_SI * chem_params%Tgas / &
    (phy_elementaryCharge_SI**2 * phy_CoulombConst_SI / &
    (chem_params%GrainRadius_CGS*1D-2))
    !(chem_params%GrainRadius_CGS*1D-2))
  if ((chem_params%Tgas .le. 0D0) .or. (chem_params%GrainRadius_CGS .le. 0D0)) then
    write(*,*) 'Abnormal Tgas or GrainRadius_CGS:'
    write(*,*) chem_params%Tgas, chem_params%GrainRadius_CGS
  end if
  ! Pagani 2009, equation 11, 12, 13
  if (TemperatureReduced .gt. 0D0) then
    JNegaPosi = (1D0 + 1D0/TemperatureReduced) * &
                (1D0 + sqrt(2D0/(2D0+TemperatureReduced)))
    JChargeNeut = 1D0 + sqrt(phy_Pi/2D0/TemperatureReduced)
  else
    JNegaPosi = 0D0
    JChargeNeut = 0D0
  end if
  !
  !sig_dust = phy_Pi * chem_params%GrainRadius_CGS * chem_params%GrainRadius_CGS
  if (chemsol_params%evol_dust_size) then
    natom_ongrain = 0D0
    do i=1, chem_species%nGrainSpecies
      i1 = chem_species%idxGrainSpecies(i)
      natom_ongrain = natom_ongrain + &
        chemsol_stor%y(i1) * sum(chem_species%elements(4:const_nElement, i1))
    end do
    natom_ongrain = natom_ongrain / chem_params%ratioDust2HnucNum
    !
    sig_dust = max(chem_params%sigdust_ave, &
      phy_Pi * (natom_ongrain / (4D0*phy_Pi/3D0))**(2D0/3D0) * grain_atom_sep_CGS**2)
    chem_params%sig_dusts = chem_params%sig_dusts0 * (sig_dust / chem_params%sigdust_ave)
  else
    sig_dust = chem_params%sigdust_ave
  end if
  !
  cosmicray_rela = chem_params%zeta_cosmicray_H2/const_cosmicRay_intensity_0 * &
    exp(-chem_params%Ncol_toISM / const_cosmicray_attenuate_N)
  Xray_rela = chem_params%zeta_Xray_H2 / const_cosmicRay_intensity_0
  !
  !Fractional coverage of H2 molecule on the dust grain surface.
  ! Garrod2011 equation (4)
  ! Only apply to desorption and surface migration rates.
  ! The reaction barrier should not be changed.
  !f_H2_cov_modi = 1D0 - 0.9D0 * min(1D0, chem_params%X_gH2 / &
  !           (chem_params%ratioDust2HnucNum * chem_params%SitesPerGrain))
  f_H2_cov_modi = 1D0
  !
  ! Le Petit 2009, equation 46 (not quite clear)
  ! Le Bourlot 1995, Appendix A
  ! Formation rate of H2:
  !   d/dt n(H2) = chem_params%R_H2_form_rate * n(H) * n_gas
  !if (chem_params%R_H2_form_rate .LT. 1D-80) then ! If not set, calculate it.
  !  ! Le Petit 2006
  !  chem_params%stickCoeffH = sqrt(10D0/max(10D0, chem_params%Tgas))
  !  chem_params%R_H2_form_rate = 0.5D0 * chem_params%stickCoeffH &
  !    * 3D0 / 4D0 * chem_params%MeanMolWeight * phy_mProton_CGS &
  !    * chem_params%ratioDust2GasMass / chem_params%GrainMaterialDensity_CGS &
  !    / sqrt(chem_params%aGrainMin_CGS * chem_params%aGrainMax_CGS) &
  !    * sqrt(8D0*phy_kBoltzmann_CGS*chem_params%Tgas/(phy_Pi * phy_mProton_CGS))
  !end if
  !
  do i=1, chem_net%nReactions
    ! Set the default value.
    chem_net%rates(i) = 0D0
    ! Reactions with very negative barriers AND with a temperature range not
    ! quite applicable are discarded.
    ! To check the most up-to-date UMIST document to see if there is any
    ! more detailed prescription for this.
    !
    ! Reactions with negative barriers are evil!!!
    !if (chem_net%ABC(3, i) .LT. -100D0) then
    !  if ((minval(chem_net%T_range(:,i)/chem_params%Tgas) .GE. 2D0) .OR. &
    !      (minval(chem_params%Tgas/chem_net%T_range(:,i)) .GE. 2D0)) then
    !    cycle
    !  end if
    !endif
    select case (chem_net%itype(i))
      case (5) !- Reactions with itype=53 need not be included.
        if (chem_params%Tgas .le. 0D0) then
          chem_net%rates(i) = 0D0
        else
          if (chem_net%ABC(3, i) .LT. 0D0) then
            if (chem_net%T_range(1, i) .gt. chem_params%Tgas) then
              ! Below the lower temperature limit
              chem_net%rates(i) = &
                chem_net%ABC(1, i) * &
                ((chem_net%T_range(1, i)/300D0)**chem_net%ABC(2, i)) &
                * exp(-chem_net%ABC(3, i)/chem_net%T_range(1, i))
            else if (chem_net%T_range(2, i) .lt. chem_params%Tgas) then
              ! Higher than the upper temperature limit
              chem_net%rates(i) = &
                chem_net%ABC(1, i) * &
                ((chem_net%T_range(2, i)/300D0)**chem_net%ABC(2, i)) &
                * exp(-chem_net%ABC(3, i)/chem_net%T_range(2, i))
            else
              chem_net%rates(i) = chem_net%ABC(1, i) * (T300**chem_net%ABC(2, i)) &
                * exp(-chem_net%ABC(3, i)/chem_params%Tgas)
            end if
          else
            chem_net%rates(i) = chem_net%ABC(1, i) * (T300**chem_net%ABC(2, i)) &
              * exp(-chem_net%ABC(3, i)/chem_params%Tgas)
          end if
        end if
      case (6) ! Similar to 5, with strict temperature range requirement
        if (chem_net%T_range(1, i) .gt. chem_params%Tgas) then
          ! Below the lower temperature limit
          chem_net%rates(i) = 0D0
        else if (chem_net%T_range(2, i) .lt. chem_params%Tgas) then
          ! Higher than the upper temperature limit
          chem_net%rates(i) = 0D0
        else
          chem_net%rates(i) = chem_net%ABC(1, i) * (T300**chem_net%ABC(2, i)) &
            * exp(-chem_net%ABC(3, i)/chem_params%Tgas)
        end if
      case (1)
        chem_net%rates(i) = &
          chem_net%ABC(1, i) * (cosmicray_rela + Xray_rela)
      case (2, 20)
        chem_net%rates(i) = &
            chem_net%ABC(1, i) &
            * (chem_net%ABC(3, i) / (1D0 - chem_params%omega_albedo) &
               * cosmicray_rela + Xray_rela)
      case (3) ! Todo
        if (chem_net%reac_names(1, i) .ne. 'H2') then
          chem_net%rates(i) = &
            chem_net%ABC(1, i) * ( &
              chem_params%G0_UV_toISM &
                * exp(-chem_net%ABC(3, i) * chem_params%Av_toISM) &
                * f_selfshielding_toISM(i) + &
              chem_params%G0_UV_toStar &
                * exp(-chem_net%ABC(3, i) * chem_params%Av_toStar) &
                * f_selfshielding_toStar(i))
        else
          chem_net%rates(i) = &
            chem_net%ABC(1, i) * ( &
              chem_params%G0_UV_toISM &
                * exp(-chem_net%ABC(3, i) * chem_params%Av_toISM) &
                * f_selfshielding_toISM(i) + &
              chem_params%G0_UV_H2phd & ! Already attenuated by dust
                * f_selfshielding_toStar(i))
        end if
      case (21) ! Ion + Grain
        if (chem_params%Tgas .le. 0D0) then
          chem_net%rates(i) = 0D0
        else
          id1 = chem_net%reac(1, i)
          id2 = chem_net%reac(2, i)
          ! Select out the non-dust reactant
          if (chem_species%elements(3, id1) .eq. 0) then
            id3 = id1
          else if (chem_species%elements(3, id2) .eq. 0) then
            id3 = id2
          else
            write(*,'(A)') 'In chem_cal_rates:'
            write(*,'(A/)') 'Species name problem with type 21.'
            call error_stop()
          end if
          ! Check whether it is a charge-neutral reaction or a negative-positive
          ! reaction
          charge1 = chem_species%elements(1, id1)
          charge2 = chem_species%elements(1, id2)
          charge3 = charge1 * charge2
          ! Get the reactant mass in gram
          m = chem_species%mass_num(id3) * phy_mProton_CGS
          ! With oposite charge
          if (charge3 .eq. -1) then
            chem_net%rates(i) = &
              sqrt(8D0*phy_kBoltzmann_CGS/phy_Pi * chem_params%Tgas / m) * &
              sig_dust * JNegaPosi
          else if (charge3 .eq. 0) then
            chem_net%rates(i) = &
              sqrt(8D0*phy_kBoltzmann_CGS/phy_Pi * chem_params%Tgas / m) * &
              sig_dust * JChargeNeut
          else
            write(*,'(A)') 'In chem_cal_rates:'
            write(*,'(A/)') 'Charge problem with type 21.'
            call error_stop()
          end if
          if (sig_dust .le. 1D-30) then
            chem_net%rates(i) = 0D0
          end if
        end if
      case (13) ! Assume phflux_Lya is already attenuated.
        ! 2014-06-18 Wed 23:42:20 ! No, not assuming phflux_Lya is already attenuated.
        chem_net%rates(i) = chem_params%phflux_Lya * chem_net%ABC(1, i) * f_selfshielding_toStar(i)
        !
      case (0)
        if (chem_params%Tgas .le. 0D0) then
          chem_net%rates(i) = 0D0
        else
          stickCoeff = getStickingCoeff(chem_net%reac(1, i), chem_params%Tgas)
          tmp = sqrt(8D0/phy_Pi * phy_kBoltzmann_CGS * chem_params%Tgas &
                     / phy_mProton_CGS)
          chem_net%rates(i) = 0.5D0 * stickCoeff * sig_dust * tmp * &
                              chem_params%ratioDust2HnucNum
          if (sig_dust .le. 1D-30) then
            chem_net%rates(i) = 0D0
          end if
        end if
        !
        chem_params%R_H2_form_rate_coeff = chem_net%rates(i)
      !
      ! itype > 60 are for grain chemistry
      !
      case (61) ! Adsorption
        ! dt(n(A)) = -sigma * v * n(A) * n(dust)
        ! dt(X(A)) = -sigma * v * X(A) * n(dust)
        ! adsorb_coeff = sigma * v * n(dust)
        if (chem_params%Tgas .le. 0D0) then
          chem_net%rates(i) = 0D0
        else
          stickCoeff = getStickingCoeff(chem_net%reac(1, i), chem_params%Tgas)
          m = chem_species%mass_num(chem_net%reac(1, i)) * phy_mProton_CGS
          chem_net%rates(i) = &
            stickCoeff * &
            chem_net%ABC(1, i) * sig_dust * &
            chem_params%ndust_tot * &
            sqrt(8D0/phy_Pi*phy_kBoltzmann_CGS*chem_params%Tgas / m)
          if (sig_dust .le. 1D-30) then
            chem_net%rates(i) = 0D0
          end if
        end if
        chem_species%adsorb_coeff(chem_net%reac(1, i)) = chem_net%rates(i)
      case (62) ! Desorption
        ! dt(N(gA)) = -desorb_coeff * N(gA)
        ! dt(X(gA)) = -desorb_coeff * X(gA)
        ! Cosmic ray desorption rate from Hasegawa1993.
        ! <timestamp>2013-08-28 Wed 12:47:30</timestamp>
        ! Error corrected: the factor vib_freq is missing for the cosmic-ray
        ! contribution
        Edesorb_eff = chem_net%ABC(3, i) * f_H2_cov_modi
        !
        chem_net%rates(i) = &
          chem_species%vib_freq(chem_net%reac(1, i)) &
          * (exp(-Edesorb_eff/chem_params%Tdust) &
             + &
             CosmicDesorpPreFactor * cosmicray_rela &
               * exp(-Edesorb_eff/CosmicDesorpGrainT))
        !
        if (sig_dust .le. 1D-30) then
          chem_net%rates(i) = 0D0
        end if
        chem_species%desorb_coeff(chem_net%reac(1, i)) = chem_net%rates(i)
        !
        ! Adopting a new prescription, in which only the topmost layers can
        ! desorb
        chem_net%rates(i) = chem_net%rates(i) * &
          (chem_params%SitesPerGrain * chem_params%ratioDust2HnucNum)
        !
      case (63) ! A + A -> B
        ! Moment equation:
        ! dt(A) = -k_AA * <A(A-1)>
        ! k_AA = k_mig(A) / N_site
        !
        ! dt(X(B)) = -k_AA / D2G * X(A)**2
        !
        ! dt(N(B)) = -k_AA / (k_AA + k_des) * sigma * v * n(a) * N(A)
        ! dt(X(B)) = -k_AA / (k_AA + k_des) * sigma * v * n(a) * X(A)
        !          = -k_AA / (k_AA + k_des) * sigma * v * X(a) * X(A) * n_gas
        !          = -k_AA / (k_AA + k_des) * sigma * v * X(a) * X(A) * n_dust / D2G
        !          = -k_AA * X(a) * X(A) * [sigma * v * n_dust] / (k_AA + k_des) / D2G
        i1 = chem_net%reac(1, i)
        tmp = getMobility(chem_species%vib_freq(i1), &
                          chem_species%mass_num(i1), &
                          chem_species%Edesorb(i1) * f_H2_cov_modi, &
                          chem_params%Tdust) / chem_params%SitesPerGrain
        branchingratio = getBranchingRatio(i)
        ! Todo
        if (chem_net%reac_names(1, i) .eq. 'gH') then
          ! Todo: A temporary way to deal with this.  To be modified later.
          !!tmp = chem_species%vib_freq(i1) / chem_params%SitesPerGrain
          !!!!
          if (chemsol_params%H2_form_use_moeq) then
            i1 = chem_species%idx_gasgrain_counterpart(chem_net%reac(1, i))
            chem_net%rates(i) = &
              tmp / (tmp + chem_species%desorb_coeff(chem_net%reac(1, i))) * &
              chem_species%adsorb_coeff(i1) / chem_params%ratioDust2HnucNum
          else
            chem_net%rates(i) = tmp / chem_params%ratioDust2HnucNum * &
                                branchingratio
          end if
          if (sig_dust .le. 1D-30) then
            chem_net%rates(i) = 0D0
          end if
          ! Note that the time unit for the rate of H2 formation to be used by
          ! the heating_cooling
          ! module must be in seconds, not in years!!
          chem_params%R_H2_form_rate_coeff = chem_net%rates(i)
        else
          chem_net%rates(i) = tmp / chem_params%ratioDust2HnucNum * &
                              branchingratio
        end if
      case (64) ! A + B -> xxx
        ! dt(A) = k_AB * <A.B>
        ! k_AB = (k_mig(A) + k_mig(B)) / N_site
        ! X(A) = N(A) * D2G; D2G: dust-to-grain-number-ratio
        ! dt(X(A)) = k_AB / D2G * X(A) * X(B)
        i1 = chem_net%reac(1, i)
        i2 = chem_net%reac(2, i)
        branchingratio = getBranchingRatio(i)
        chem_net%rates(i) = ( &
          getMobility(chem_species%vib_freq(i1), &
                      chem_species%mass_num(i1), &
                      chem_species%Edesorb(i1) * f_H2_cov_modi, &
                      chem_params%Tdust) &
          + &
          getMobility(chem_species%vib_freq(i2), &
                      chem_species%mass_num(i2), &
                      chem_species%Edesorb(i2) * f_H2_cov_modi, &
                      chem_params%Tdust)) &
          / (chem_params%SitesPerGrain * chem_params%ratioDust2HnucNum) &
          * branchingratio
        if (sig_dust .le. 1D-30) then
          chem_net%rates(i) = 0D0
        end if
      case (75) ! Photodesorption
        photoyield = chem_net%ABC(1, i) + chem_net%ABC(2, i) * chem_params%Tdust
        chem_net%rates(i) = &
          (chem_params%G0_UV_toStar_photoDesorb * phy_Habing_photon_flux_CGS & ! From star
           + &
           chem_params%G0_UV_toISM * phy_Habing_photon_flux_CGS & ! From ISM
             * exp(-phy_UVext2Av*chem_params%Av_toISM)) &
          * sig_dust &
          * chem_params%ratioDust2HnucNum &
          * photoyield
        if (sig_dust .le. 1D-30) then
          chem_net%rates(i) = 0D0
        end if
      case default
        chem_net%rates(i) = 0D0
    end select
    !
    ! Change the time unit from seconds into years.
    chem_net%rates(i) = chem_net%rates(i) * phy_SecondsPerYear
    !
    ! dn/dt = k n1 n2 => dx/dt := d(n/n_H)/dt = k*n_H x1 x2
    if ((chem_net%n_reac(i) .EQ. 2) .and. (chem_net%itype(i) .lt. 60)) then
      chem_net%rates(i) = chem_net%rates(i) * chem_params%n_gas
    end if
    !
    ! Choose the reaction with temperature range that
    ! best matches the current temperature.
    ! Since different locations can have very different temperatures,
    ! it is important to do this for each location.
    if (chem_net%dupli(i)%nItem .GT. 0) then
      do j=1, chem_net%dupli(i)%nItem
        k = chem_net%dupli(i)%list(j)
        tmpVecReal(1:2) = abs(chem_net%T_range(:,k) - chem_params%Tgas)
        tmpVecReal(3:4) = abs(chem_net%T_range(:,i) - chem_params%Tgas)
        tmpVecInt = minloc(tmpVecReal)
        i1 = tmpVecInt(1)
        if ((i1 .EQ. 1) .OR. (i1 .EQ. 2)) then
          chem_net%rates(i) = 0D0
          exit
        end if
        if ((i1 .EQ. 3) .OR. (i1 .EQ. 4)) then
          chem_net%rates(k) = 0D0
          cycle
        end if
      end do
    end if
  end do
end subroutine chem_cal_rates



subroutine update_gH_params(n, y)
    !
    integer, intent(in) :: n
    double precision, dimension(n), intent(in) :: y
    integer i_gH
    double precision ice_coverage, Edesorb_gH
    !
    ice_coverage = get_ice_coverage(n, y)
    Edesorb_gH = chemsol_params%Edesorb_gH_bare_grain * (1D0 - ice_coverage) + &
                 chemsol_params%Edesorb_gH_icy_grain  * ice_coverage
    i_gH = chem_idx_some_spe%i_gH
    chem_species%Edesorb(i_gH) = Edesorb_gH
    chem_species%vib_freq(i_gH) = &
        getVibFreq(chem_species%mass_num(i_gH), Edesorb_gH)
    !
end subroutine update_gH_params



function get_ice_coverage(n, y)
    integer, intent(in) :: n
    double precision, dimension(n), intent(in) :: y
    integer i, i1
    double precision n_molecule_on_grain
    double precision get_ice_coverage
    n_molecule_on_grain = 0D0
    do i=1, chem_species%nGrainSpecies
      i1 = chem_species%idxGrainSpecies(i)
      n_molecule_on_grain = n_molecule_on_grain + y(i1)
    end do
    n_molecule_on_grain = n_molecule_on_grain / chem_params%ratioDust2HnucNum
    chem_params%n_mol_on_grain = n_molecule_on_grain
    get_ice_coverage = min(1D0, n_molecule_on_grain / chem_params%SitesPerGrain)
end function get_ice_coverage



function f_selfshielding_toISM(iReac)
  double precision f_selfshielding_toISM
  integer iReac
  if ((chem_net%ctype(iReac) .NE. 'PH') .and. &
      (chem_net%ctype(iReac) .NE. 'LA')) then
    ! 2014-06-11 Wed 01:02:09
    ! Sh*t!  Forgot to correct this previously!
    f_selfshielding_toISM = 1D0
    return
  end if
  select case (chem_species%names(chem_net%reac(1, iReac)))
    case ('H2')
      f_selfshielding_toISM = chem_params%f_selfshielding_toISM_H2
    case ('CO')
      f_selfshielding_toISM = chem_params%f_selfshielding_toISM_CO
    case ('H2O')
      f_selfshielding_toISM = chem_params%f_selfshielding_toISM_H2O
    case ('OH')
      f_selfshielding_toISM = chem_params%f_selfshielding_toISM_OH
    !case ('C')
    !  f_selfshielding_toISM = chem_params%f_selfshielding_toISM_H2
    case default
      f_selfshielding_toISM = 1D0
  end select
end function f_selfshielding_toISM




function f_selfshielding_toStar(iReac)
  double precision f_selfshielding_toStar
  integer iReac
  !write(*,*) iReac, chem_net%ctype(iReac), chem_species%names(chem_net%reac(1, iReac))
  !write(*,*) chem_net%ctype(iReac) .NE. 'PH', chem_net%ctype(iReac) .NE. 'LA'
  if ((chem_net%ctype(iReac) .NE. 'PH') .and. &
      (chem_net%ctype(iReac) .NE. 'LA')) then
    ! 2014-06-08 Sun 15:59:52
    ! Bug found.
    ! Change .or. into .and.
    f_selfshielding_toStar = 1D0
    return
  end if
  select case (chem_species%names(chem_net%reac(1, iReac)))
    case ('H2')
      f_selfshielding_toStar = chem_params%f_selfshielding_toStar_H2
    case ('CO')
      f_selfshielding_toStar = chem_params%f_selfshielding_toStar_CO
    case ('H2O')
      f_selfshielding_toStar = chem_params%f_selfshielding_toStar_H2O
    case ('OH')
      f_selfshielding_toStar = chem_params%f_selfshielding_toStar_OH
    !case ('C')
    !  f_selfshielding_toStar = chem_params%f_selfshielding_toStar_H2
    case default
      f_selfshielding_toStar = 1D0
  end select
end function f_selfshielding_toStar




function getStickingCoeff(iSpe, T) result(s)
  ! Roughly based on equation 1 and table 1 of Chaabouni 2012
  ! Very exact formula may not be necessary.
  double precision s
  integer, intent(in) :: iSpe
  double precision, intent(in) :: T
  double precision, parameter :: beta = 2.5D0
  double precision, parameter :: S0_H = 1.0D0
  double precision, parameter :: T0_aswice_H = 52D0
  double precision, parameter :: T0_silicate_H = 25D0
  double precision, parameter :: T0_H = 0.5D0*(T0_aswice_H+T0_silicate_H)
  double precision, parameter :: T_aswice = 100D0
  double precision T0, r, tmp
  !
  T0 = chem_species%mass_num(iSpe) * T0_H
  r = T / T0
  tmp = (1D0 + r) * (1D0 + r) * sqrt(1D0 + r) ! = (1+r)**beta
  s = S0_H * (1D0 + beta*r) / tmp
end function getStickingCoeff

! To get index of few special grains.
subroutine chem_get_idx_for_special_species
  integer i
  allocate(chem_idx_some_spe%idx(chem_idx_some_spe%nItem))
  chem_idx_some_spe%idx = 0
  chem_idx_some_spe%i_Grain0 = 0
  chem_idx_some_spe%i_GrainM = 0
  chem_idx_some_spe%i_GrainP = 0
  chem_idx_some_spe%i_gH = 0
  chem_idx_some_spe%i_gH2 = 0
  chem_idx_some_spe%i_gH2O = 0
  chem_idx_some_spe%i_gCO = 0
  chem_idx_some_spe%i_gCO2 = 0
  chem_idx_some_spe%i_gN2 = 0
  do i=1, chem_species%nSpecies
    select case (trim(chem_species%names(i)))
      case ('H2')
        chem_idx_some_spe%i_H2 = i
        chem_idx_some_spe%iiH2 = 1
        chem_idx_some_spe%idx(1) = i
      case ('H')
        chem_idx_some_spe%i_HI = i
        chem_idx_some_spe%iiHI = 2
        chem_idx_some_spe%idx(2) = i
      case ('E-')
        chem_idx_some_spe%i_E = i
        chem_idx_some_spe%iiE = 3
        chem_idx_some_spe%idx(3) = i
      case ('C')
        chem_idx_some_spe%i_CI = i
        chem_idx_some_spe%iiCI = 4
        chem_idx_some_spe%idx(4) = i
      case ('C+')
        chem_idx_some_spe%i_CII = i
        chem_idx_some_spe%iiCII = 5
        chem_idx_some_spe%idx(5) = i
      case ('O')
        chem_idx_some_spe%i_OI = i
        chem_idx_some_spe%iiOI = 6
        chem_idx_some_spe%idx(6) = i
      case ('O2')
        chem_idx_some_spe%i_O2 = i
        chem_idx_some_spe%iiO2 = 7
        chem_idx_some_spe%idx(7) = i
      case ('CO')
        chem_idx_some_spe%i_CO = i
        chem_idx_some_spe%iiCO = 8
        chem_idx_some_spe%idx(8) = i
      case ('H2O')
        chem_idx_some_spe%i_H2O = i
        chem_idx_some_spe%iiH2O = 9
        chem_idx_some_spe%idx(9) = i
      case ('OH')
        chem_idx_some_spe%i_OH = i
        chem_idx_some_spe%iiOH = 10
        chem_idx_some_spe%idx(10) = i
      case ('H+')
        chem_idx_some_spe%i_Hplus = i
      case ('He+')
        chem_idx_some_spe%i_Heplus = i
      case ('gH')
        chem_idx_some_spe%i_gH = i
      case ('gH2')
        chem_idx_some_spe%i_gH2 = i
      case ('Grain0')
        chem_idx_some_spe%i_Grain0 = i
      case ('Grain-')
        chem_idx_some_spe%i_GrainM = i
      case ('Grain+')
        chem_idx_some_spe%i_GrainP = i
      case ('gH2O')
        chem_idx_some_spe%i_gH2O = i
      case ('gCO')
        chem_idx_some_spe%i_gCO = i
      case ('gCO2')
        chem_idx_some_spe%i_gCO2 = i
      case ('gN2')
        chem_idx_some_spe%i_gN2 = i
      case ('N+')
        chem_idx_some_spe%i_NII = i
      case ('Si+')
        chem_idx_some_spe%i_SiII = i
      case ('Fe+')
        chem_idx_some_spe%i_FeII = i
      case ('N')
        chem_idx_some_spe%i_NI = i
    end select
  end do
  do i=1, chem_idx_some_spe%nItem
    if (chem_idx_some_spe%idx(i) .eq. 0) then
      write(*, '(A, A)') chem_idx_some_spe%names(i), &
        ' does not have an index!'
    end if
  end do
  if (chem_idx_some_spe%i_Grain0 .eq. 0) then
    write(*, '(A/)') 'Grain0 does not have an index!'
  end if
end subroutine chem_get_idx_for_special_species

! To find the reactions with same reactants, 
! products and reaction types and find the ones with smaller indices.
subroutine chem_get_dupli_reactions
  ! Find out the duplicated reactions.
  ! Among all the reaction belonging to a single "duplicated set",
  ! one and only one will be used.
  ! For each reaction, this subroutine finds out all the reactions with smaller
  ! indices and the same reactants, products, and reaction types.
  integer i, j, i1, ndup
  integer, dimension(const_n_dupli_max_guess) :: indices
  ndup = 0
  do i=1, chem_net%nReactions
    chem_net%dupli(i)%nItem = 0
    i1 = 0
    do j=1, i-1
      if ((chem_net%ctype(i) .EQ. chem_net%ctype(j)) .AND. &
          (chem_net%itype(i) .EQ. chem_net%itype(j)) .AND. &
          (sum(abs(chem_net%reac(:, j)-chem_net%reac(:, i))) .EQ. 0) .AND. &
          (sum(abs(chem_net%prod(:, j)-chem_net%prod(:, i))) .EQ. 0)) then
        i1 = i1 + 1
        indices(i1) = j
      end if
    end do
    if (i1 .GT. 0) then
      chem_net%dupli(i)%nItem = i1
      allocate(chem_net%dupli(i)%list(i1))
      chem_net%dupli(i)%list = indices(1:i1) 
    end if
    ndup = ndup + i1
  end do
  write(*, '(A, I6)') 'Number of reactions with a duplicate counterpart: ', ndup
end subroutine chem_get_dupli_reactions


! Parsing reactions, i.e storing te reactions in arrays
! and getting the name of species involved.
subroutine chem_parse_reactions
  integer i, j, k, n_tmp
  logical flag
  integer, dimension(:), allocatable :: eLeft, eRight
  character(len=const_len_species_name), &
    dimension(const_nSpecies_guess) :: names_tmp
  !
  ! Build up index array of all the reactions, and get the name of all the
  ! species.
  chem_net%reac = 0
  chem_net%prod = 0
  names_tmp(1) = chem_net%reac_names(1, 1)
  n_tmp = 1
  do i=1, chem_net%nReactions
    do k=1, chem_net%n_reac(i)
      flag = .TRUE.
      do j=1, n_tmp
        if (trim(names_tmp(j)) .EQ. trim(chem_net%reac_names(k, i))) then
          flag = .FALSE.
          chem_net%reac(k, i) = j
          exit
        end if
      end do
      if (flag) then
        n_tmp = n_tmp + 1
        names_tmp(n_tmp) = chem_net%reac_names(k, i)
        chem_net%reac(k, i) = n_tmp
      end if
    end do
    do k=1, chem_net%n_prod(i)
      flag = .TRUE.
      do j=1, n_tmp
        if (trim(names_tmp(j)) .EQ. trim(chem_net%prod_names(k, i))) then
          flag = .FALSE.
          chem_net%prod(k, i) = j
          exit
        end if
      end do
      if (flag) then
        n_tmp = n_tmp + 1
        names_tmp(n_tmp) = chem_net%prod_names(k, i)
        chem_net%prod(k, i) = n_tmp
      end if
    end do
  end do
  !
  chem_species%nSpecies = n_tmp
  allocate( &
        chem_species%names(n_tmp), &
        chem_species%mass_num(n_tmp), &
        chem_species%vib_freq(n_tmp), &
        chem_species%Edesorb(n_tmp), &
        chem_species%adsorb_coeff(n_tmp), &
        chem_species%desorb_coeff(n_tmp), &
        chem_species%idx_gasgrain_counterpart(n_tmp), &
        chem_species%elements(const_nElement, n_tmp))
  !
  chem_species%names = names_tmp(1:n_tmp)
  !
  ! Initialize to invalid values so that error will be explicitly shown (just
  ! in case).
  chem_species%vib_freq = dblNaN()
  chem_species%Edesorb = dblNaN()
  chem_species%adsorb_coeff = dblNaN()
  chem_species%desorb_coeff = dblNaN()
  chem_species%idx_gasgrain_counterpart = -1
  do i=1, chem_species%nSpecies
    call getElements(chem_species%names(i), const_nameElements, &
                     const_nElement, chem_species%elements(:, i))
    chem_species%mass_num(i) = dot_product(dble(chem_species%elements(:, i)), &
                                   const_ElementMassNumber)
  end do
  !
  ! deallocate(chem_species%elements)
  !
  allocate(eLeft(const_nElement), eRight(const_nElement))
  !
  n_tmp = 0
  do i=1, chem_net%nReactions
    !
    ! Check for elemental conservation
    eLeft = 0
    eRight = 0
    do j=1, chem_net%n_reac(i)
      eLeft = eLeft + chem_species%elements(:, chem_net%reac(j, i))
    end do
    do j=1, chem_net%n_prod(i)
      eRight = eRight + chem_species%elements(:, chem_net%prod(j, i))
    end do
    ! Electron number is not expected to be conserved.
    ! 2 is the index for electron
    if ((sum(abs(eLeft(3:const_nElement) - eRight(3:const_nElement))) &
         + abs(eLeft(1) - eRight(1))) .ne. 0) then
      n_tmp = n_tmp + 1
      write(*, '(A)') 'Elements not conserved: '
      write(*, '(6A12, 3ES12.3)') chem_net%reac_names(1:2, i), &
                                  chem_net%prod_names(1:4, i), &
                                  chem_net%ABC(:, i)
    end if
    !
    select case (chem_net%itype(i))
      case (62)
        ! Get the desorption energy and vibrational frequencies based on the
        ! desorption reaction parameters.
        chem_species%vib_freq(chem_net%reac(1, i)) = &
          getVibFreq(chem_species%mass_num(chem_net%reac(1, i)), &
                     chem_net%ABC(3, i))
        chem_species%Edesorb(chem_net%reac(1, i)) = chem_net%ABC(3, i)
        ! Get the gas phase counter part of grain species, and vice versa.
        chem_species%idx_gasgrain_counterpart(chem_net%prod(1, i)) = chem_net%reac(1, i)
        chem_species%idx_gasgrain_counterpart(chem_net%reac(1, i)) = chem_net%prod(1, i)
      case default
        cycle
    end select
  end do
  if (n_tmp .eq. 0) then
    write(*, '(A/)') 'Elements are conserved in all the reactions.'
  else
    write(*, '(I5, A/)') n_tmp, ' reactions do not conserve elements!'
  end if
  !
  ! Get all the grain species
  chem_species%nGrainSpecies = 0
  do i=1, chem_species%nSpecies
    if (chem_species%names(i)(1:1) .eq. const_grainSpe_prefix) then
      chem_species%nGrainSpecies = chem_species%nGrainSpecies + 1
    end if
  end do
  if (chem_species%nGrainSpecies .gt. 0) then
    allocate(chem_species%idxGrainSpecies(chem_species%nGrainSpecies))
    n_tmp = 0
    do i=1, chem_species%nSpecies
      if (chem_species%names(i)(1:1) .eq. const_grainSpe_prefix) then
        n_tmp = n_tmp + 1
        chem_species%idxGrainSpecies(n_tmp) = i
      end if
    end do
  end if
  deallocate(eLeft, eRight)
end subroutine chem_parse_reactions


! To load the chemical reactions
subroutine chem_load_reactions
  integer i, j, k, ios
  chem_net%nReactions = chem_reac_str%nReactions
  allocate(chem_net%reac_names(const_n_reac_max, chem_net%nReactions), &
           chem_net%prod_names(const_n_prod_max, chem_net%nReactions), &
           chem_net%reac(const_n_reac_max, chem_net%nReactions), &
           chem_net%prod(const_n_prod_max, chem_net%nReactions), &
           chem_net%n_reac(chem_net%nReactions), &
           chem_net%n_prod(chem_net%nReactions), &
           chem_net%ABC(3, chem_net%nReactions), &
           chem_net%T_range(2, chem_net%nReactions), &
           chem_net%itype(chem_net%nReactions), &
           chem_net%ctype(chem_net%nReactions), &
           chem_net%reliability(chem_net%nReactions), &
           chem_net%rates(chem_net%nReactions), &
           chem_net%dupli(chem_net%nReactions))
  chem_net%reac_names = ' '
  chem_net%prod_names = ' '
  chem_net%n_reac = 0
  chem_net%n_prod = 0
  chem_net%rates = 0D0
  do i=1, chem_net%nReactions
    read(chem_reac_str%list(i), FMT = &
      '(7(A12), 3F9.0, 2F6.0, I3, X, A1, X, A2)', IOSTAT=ios) &
      chem_net%reac_names(:,i), &
      chem_net%prod_names(:,i), &
      chem_net%ABC(:,i), &
      chem_net%T_range(:,i), &
      chem_net%itype(i), &
      chem_net%reliability(i), &
      chem_net%ctype(i)
    do j=1, const_n_reac_max
      do k=1, const_len_species_name
        if (chem_net%reac_names(j, i)(k:k) .NE. ' ') then
          chem_net%n_reac(i) = chem_net%n_reac(i) + 1
          exit
        end if
      end do
      if (trim(chem_net%reac_names(j, i)) .EQ. 'PHOTON') then
        chem_net%n_reac(i) = chem_net%n_reac(i) - 1
      end if
      if (trim(chem_net%reac_names(j, i)) .EQ. 'CRPHOT') then
        chem_net%n_reac(i) = chem_net%n_reac(i) - 1
      end if
      if (trim(chem_net%reac_names(j, i)) .EQ. 'CRP') then
        chem_net%n_reac(i) = chem_net%n_reac(i) - 1
      end if
    end do
    do j=1, const_n_prod_max
      do k=1, const_len_species_name
        if (chem_net%prod_names(j, i)(k:k) .NE. ' ') then
          chem_net%n_prod(i) = chem_net%n_prod(i) + 1
          exit
        end if
      end do
      if (trim(chem_net%prod_names(j, i)) .EQ. 'PHOTON') then
        chem_net%n_prod(i) = chem_net%n_prod(i) - 1
      end if
    end do
  end do
end subroutine chem_load_reactions

! To read the chemical reactions
subroutine chem_read_reactions()
  integer fU, i, ios
  chem_reac_str%nReactions = &
    GetFileLen_comment_blank(combine_dir_filename(chemsol_params%chem_files_dir, &
                             chemsol_params%filename_chemical_network), &
    chem_reac_str%commentChar)
  call openFileSequentialRead(fU, combine_dir_filename(chemsol_params%chem_files_dir, &
       chemsol_params%filename_chemical_network), 999, getu=1)
  allocate(chem_reac_str%list(chem_reac_str%nReactions))
  i = 1
  do
    read(fU, FMT='(A)', IOSTAT=ios) chem_reac_str%list(i)
    if (ios .NE. 0) then
      exit
    end if
    if (.NOT. &
        ( &
         (chem_reac_str%list(i)(1:1) .EQ. chem_reac_str%commentChar) .OR. &
         (chem_reac_str%list(i)(1:1) .EQ. ' ') &
        )) then
      i = i + 1
    end if
    if (i .GT. chem_reac_str%nReactions) then
      exit
    end if
  end do
  close(fU)
end subroutine chem_read_reactions


! Get the elemental composition of each molecule.
subroutine getElements &
  (nameSpec, listElements, nElements, arrNElements)
character(len=*) nameSpec, listElements(nElements)
integer, dimension(nElements) :: arrNElements
integer i, j, k, ntmp, lenName, lenEle, nElements
integer, dimension(32) :: belongto
logical, dimension(32) :: used
logical flagReplace
integer, parameter :: chargePos = 1
arrNElements = 0
lenName = len(trim(nameSpec))
belongto = 0
used = .FALSE.
do i=1, nElements
  lenEle = len(trim(listElements(i)))
  do j=1, lenName-lenEle+1
    if (nameSpec(j:(j+lenEle-1)) .EQ. &
        listElements(i)(1:(lenEle))) then
      flagReplace = .TRUE.
      do k=j, (j+lenEle-1)
        if (used(k)) then
          if (len(trim(listElements(belongto(k)))) .GE. &
              len(trim(listElements(i)))) then
            flagReplace = .FALSE.
            exit
          else
            arrNElements(belongto(k)) = &
              arrNElements(belongto(k)) - 1
          end if
        end if
      end do
      if (flagReplace) then
        belongto(j:(j+lenEle-1)) = i
        used(j:(j+lenEle-1)) = .TRUE.
        arrNElements(i) = arrNElements(i) + 1
      end if
    end if
  end do
end do
!
do i=2, lenName
  if (.NOT. used(i)) then
    do j=1, (i-1)
      if (used(i-j)) then
        belongto(i) = belongto(i-j)
        exit
      end if
    end do
    if (((nameSpec(i-1:i-1) .GT. '9') .OR. &
      (nameSpec(i-1:i-1) .LT. '0')) .AND. &
      (nameSpec(i:i) .LE. '9') .AND. &
      (nameSpec(i:i) .GE. '0')) then
      if ((nameSpec(i+1:i+1) .LE. '9') .AND. &
        (nameSpec(i+1:i+1) .GE. '0')) then
        read (nameSpec(i:i+1), '(I2)') ntmp
        if (ntmp .EQ. 0) cycle
        arrNElements(belongto(i)) = &
          arrNElements(belongto(i)) + ntmp - 1
      else
        read (nameSpec(i:i), '(I1)') ntmp
        if (ntmp .EQ. 0) cycle
        arrNElements(belongto(i)) = &
          arrNElements(belongto(i)) + ntmp - 1
      end if
    else if (nameSpec(i:i) .EQ. '+') then
      arrNElements(chargePos) = 1
    else if (nameSpec(i:i) .EQ. '-') then
      arrNElements(chargePos) = -1
    end if
  end if
end do
end subroutine getElements


function getVibFreq(massnum, Edesorb)
double precision getVibFreq
double precision, intent(in) :: massnum, Edesorb
getVibFreq = &
   sqrt(2D0 * const_SitesDensity_CGS * &
      phy_kBoltzmann_CGS * Edesorb / (phy_Pi**2) / &
      (phy_mProton_CGS * massnum))
end function getVibFreq


function getMobility(vibfreq, massnum, Edesorb, Tdust)
  double precision getMobility
  double precision, intent(in) :: vibfreq, massnum, Edesorb, Tdust
  double precision, parameter :: DiffBarrierWidth_CGS = 1D-8
  double precision E_diff_gH
  ! Edesorb is in Kelvin.
  ! 2a/hbar * sqrt(2mE)
  getMobility = vibfreq * exp(max( &
              -Edesorb * chemsol_params%Diff2DesorRatio / Tdust, &
              !
              -2D0 * DiffBarrierWidth_CGS / phy_hbarPlanck_CGS * &
                sqrt(2D0 * massnum * (phy_mProton_CGS &
                  * phy_kBoltzmann_CGS * chemsol_params%Diff2DesorRatio) * Edesorb)))
  if ((abs(massnum-1D0) .le. 1D-4) .and. (chemsol_params%use_special_gH_mobi) .and. &
      (.not. chemsol_params%update_gH_params_realtime)) then
    E_diff_gH = chemsol_params%special_gH_E_diff
    getMobility = vibfreq * exp(max( &
                -E_diff_gH / Tdust, &
                !
                -2D0 * DiffBarrierWidth_CGS / phy_hbarPlanck_CGS * &
                  sqrt(2D0 * massnum * (phy_mProton_CGS &
                    * phy_kBoltzmann_CGS * E_diff_gH))))
  end if
  if (isnan(getMobility)) then
    getMobility = 0D0
  end if
end function getMobility


function getBranchingRatio(idx)
  integer, intent(in) :: idx
  double precision getBranchingRatio
  if (chem_net%itype(idx) .lt. 63) then
    getBranchingRatio = 1D0
    return
  end if
  if (chem_net%ABC(3, idx) .NE. 0D0) then
    getBranchingRatio = chem_net%ABC(1, idx) * exp(max( &
      -chem_net%ABC(3, idx) / chem_params%Tdust, &
      -2D0 * chem_net%ABC(2, idx) * 1D-8 / phy_hbarPlanck_CGS * &
        sqrt(2D0 * chem_net%T_range(1, idx) * phy_mProton_CGS &
             * phy_kBoltzmann_CGS * chem_net%ABC(3, idx))))
  else
    getBranchingRatio = chem_net%ABC(1, idx)
  end if
  if (isnan(getBranchingRatio)) then
    getBranchingRatio = 0D0
  end if
end function getBranchingRatio

! To store all the different chemical elements.
subroutine chem_elemental_residence
  use quick_sort
  double precision, dimension(:,:), allocatable :: ele_spe, tmp
  integer i, j, i0
  double precision accum, accum_total
  allocate(ele_spe(const_nElement, chem_species%nSpecies), &
           tmp(2, chem_species%nSpecies))
  if (.not. allocated(chem_ele_resi)) then
    allocate(chem_ele_resi(const_nElement))
  end if
  do i=1, chem_species%nSpecies
    ele_spe(:, i) = chemsol_stor%y(i) * dble(chem_species%elements(:,i))
  end do
  do i=1, const_nElement
    if (.not. allocated(chem_ele_resi(i)%ele_frac)) then
      allocate(chem_ele_resi(i)%ele_frac(chem_ele_resi_nmax), &
              chem_ele_resi(i)%ele_accu(chem_ele_resi_nmax), &
              chem_ele_resi(i)%iSpecies(chem_ele_resi_nmax))
    end if
    do j=1, chem_species%nSpecies
      tmp(1, j) = dble(j)
    end do
    tmp(2, :) = -abs(ele_spe(i, :))
    call quick_sort_array(tmp, 2, chem_species%nSpecies, 1, (/2/))
    accum = 0D0
    accum_total = sum(abs(ele_spe(i, :)))
    chem_ele_resi(i)%n_nonzero = chem_ele_resi_nmax
    do j=1, chem_ele_resi_nmax
      i0 = int(tmp(1, j))
      accum = accum + abs(ele_spe(i, i0))
      if (abs(ele_spe(i, i0)) .ge. 1D-90) then
        chem_ele_resi(i)%ele_frac(j) = ele_spe(i, i0) / accum_total
        chem_ele_resi(i)%ele_accu(j) = accum / accum_total
      else
        chem_ele_resi(i)%ele_frac(j) = 0D0
        chem_ele_resi(i)%ele_accu(j) = 0D0
      end if
      chem_ele_resi(i)%iSpecies(j) = i0
      if ((accum .ge. chem_ele_frac_threshold_to_sum * accum_total) .or. &
          (abs(chem_ele_resi(i)%ele_frac(j)) .le. &
           chem_ele_frac_threshold_to_max * chem_ele_resi(i)%ele_frac(1))) then
        chem_ele_resi(i)%n_nonzero = j
        exit
      end if
    end do
  end do
  deallocate(ele_spe, tmp)
end subroutine chem_elemental_residence

! To find out how much of a species is produced
! or destroyed, after a number of repetitions, using the reactions.
subroutine get_species_produ_destr
  integer i, j, k, i0
  logical flag_repeat
  integer, dimension(:), allocatable :: counter1, counter2
  if (allocated(chem_species%produ)) then
    ! Already done before
    return
  end if
  allocate(chem_species%produ(chem_species%nSpecies), &
           chem_species%destr(chem_species%nSpecies))
  chem_species%produ%nItem = 0
  chem_species%destr%nItem = 0
  do i=1, chem_net%nReactions
    do j=1, chem_net%n_reac(i)
      flag_repeat = .false.
      do k=1, j-1
        if (chem_net%reac(k, i) .eq. chem_net%reac(j, i)) then
          flag_repeat = .true.
          exit
        end if
      end do
      if (flag_repeat) then
        cycle
      end if
      i0 = chem_net%reac(j, i)
      chem_species%destr(i0)%nItem = chem_species%destr(i0)%nItem + 1
    end do
    do j=1, chem_net%n_prod(i)
      flag_repeat = .false.
      do k=1, j-1
        if (chem_net%prod(k, i) .eq. chem_net%prod(j, i)) then
          flag_repeat = .true.
          exit
        end if
      end do
      if (flag_repeat) then
        cycle
      end if
      i0 = chem_net%prod(j, i)
      chem_species%produ(i0)%nItem = chem_species%produ(i0)%nItem + 1
    end do
  end do
  do i=1, chem_species%nSpecies
    allocate(chem_species%produ(i)%list(chem_species%produ(i)%nItem), &
             chem_species%destr(i)%list(chem_species%destr(i)%nItem), &
             chem_species%produ(i)%n_repeat(chem_species%produ(i)%nItem), &
             chem_species%destr(i)%n_repeat(chem_species%destr(i)%nItem), &
             chem_species%produ(i)%contri(chem_species%produ(i)%nItem), &
             chem_species%destr(i)%contri(chem_species%destr(i)%nItem))
  end do
  allocate(counter1(chem_species%nSpecies), counter2(chem_species%nSpecies))
  counter1 = 0
  counter2 = 0
  do i=1, chem_net%nReactions
    do j=1, chem_net%n_reac(i)
      flag_repeat = .false.
      do k=1, j-1
        if (chem_net%reac(k, i) .eq. chem_net%reac(j, i)) then
          flag_repeat = .true.
          exit
        end if
      end do
      if (flag_repeat) then
        cycle
      end if
      i0 = chem_net%reac(j, i)
      counter1(i0) = counter1(i0) + 1
      chem_species%destr(i0)%list(counter1(i0)) = i
    end do
    do j=1, chem_net%n_prod(i)
      flag_repeat = .false.
      do k=1, j-1
        if (chem_net%prod(k, i) .eq. chem_net%prod(j, i)) then
          flag_repeat = .true.
          exit
        end if
      end do
      if (flag_repeat) then
        cycle
      end if
      i0 = chem_net%prod(j, i)
      counter2(i0) = counter2(i0) + 1
      chem_species%produ(i0)%list(counter2(i0)) = i
    end do
  end do
  do i=1, chem_species%nSpecies
    chem_species%produ(i)%n_repeat = 0
    chem_species%destr(i)%n_repeat = 0
    do j=1, chem_species%produ(i)%nItem
      i0 = chem_species%produ(i)%list(j)
      do k=1, chem_net%n_prod(i0)
        if (chem_net%prod(k, i0) .eq. i) then
          chem_species%produ(i)%n_repeat(j) = &
            chem_species%produ(i)%n_repeat(j) + 1
        end if
      end do
    end do
    do j=1, chem_species%destr(i)%nItem
      i0 = chem_species%destr(i)%list(j)
      do k=1, chem_net%n_reac(i0)
        if (chem_net%reac(k, i0) .eq. i) then
          chem_species%destr(i)%n_repeat(j) = &
            chem_species%destr(i)%n_repeat(j) + 1
        end if
      end do
    end do
  end do
  deallocate(counter1, counter2)
end subroutine get_species_produ_destr

! Using the rates, find out how much of an individual
! species is produced and destroyed.
subroutine get_contribution_each
  use quick_sort
  integer i, j, ireac
  double precision, dimension(:), allocatable :: rates_all
  double precision, dimension(:,:), allocatable :: tmp
  allocate(rates_all(chem_net%nReactions), &
           tmp(2, chem_net%nReactions))
  call chem_ode_f_alt(chem_net%nReactions, rates_all, &
                      chemsol_params%NEQ, chemsol_stor%y)
  do i=1, chem_species%nSpecies
    do j=1, chem_species%produ(i)%nItem
      ireac = chem_species%produ(i)%list(j)
      chem_species%produ(i)%contri(j) = &
        dble(chem_species%produ(i)%n_repeat(j)) * rates_all(ireac)
      tmp(1, j) = dble(ireac)
    end do
    tmp(2, 1:chem_species%produ(i)%nItem) = -chem_species%produ(i)%contri
    call quick_sort_array(tmp(:, 1:chem_species%produ(i)%nItem), &
        2, chem_species%produ(i)%nItem, 1, (/2/))
    chem_species%produ(i)%contri = -tmp(2, 1:chem_species%produ(i)%nItem)
    chem_species%produ(i)%list   = int(tmp(1, 1:chem_species%produ(i)%nItem))
    !
    do j=1, chem_species%destr(i)%nItem
      ireac = chem_species%destr(i)%list(j)
      chem_species%destr(i)%contri(j) = &
        dble(chem_species%destr(i)%n_repeat(j)) * rates_all(ireac)
      tmp(1, j) = dble(ireac)
    end do
    tmp(2, 1:chem_species%destr(i)%nItem) = -chem_species%destr(i)%contri
    call quick_sort_array(tmp(:, 1:chem_species%destr(i)%nItem), &
        2, chem_species%destr(i)%nItem, 1, (/2/))
    chem_species%destr(i)%contri = -tmp(2, 1:chem_species%destr(i)%nItem)
    chem_species%destr(i)%list   = int(tmp(1, 1:chem_species%destr(i)%nItem))
  end do
  deallocate(rates_all, tmp)
end subroutine get_contribution_each

! To set the method to calculate rate for different types of
! reactions.
subroutine chem_ode_f_alt(nr, r, ny, y)
  double precision, dimension(nr), intent(out) :: r
  double precision, dimension(ny), intent(in) :: y
  integer, intent(in) :: nr, ny
  integer i, i1
  double precision tmp
  r = 0D0
  !
  if (chemsol_params%evolT .and. (ny .ge. chem_species%nSpecies+1)) then
    if (y(chem_species%nSpecies+1) .ne. chem_params%Tgas) then
      chem_params%Tgas = y(chem_species%nSpecies+1)
      call chem_cal_rates
    end if
  end if
  !
  do i=1, chem_net%nReactions
    select case (chem_net%itype(i))
      case (5, 6, 21, 64) ! A + B -> C ! 53
        r(i) = chem_net%rates(i) * y(chem_net%reac(1, i)) * y(chem_net%reac(2, i))
      case (1, 2, 3, 13, 61, 0, 20) ! A -> B
        r(i) = chem_net%rates(i) * y(chem_net%reac(1, i))
      case (62)
        tmp = y(chem_net%reac(1, i)) / &
          (chem_params%ratioDust2HnucNum * chem_params%SitesPerGrain)
        if (tmp .le. 1D-9) then
          r(i) = chem_net%rates(i) * tmp
        else
          r(i) = chem_net%rates(i) * (1D0 - exp(-tmp))
        end if
      case (75)
        tmp = y(chem_net%reac(1, i)) / &
          (chem_params%ratioDust2HnucNum * chem_params%SitesPerGrain &
           * chem_net%ABC(3, i))
        if (tmp .le. 1D-9) then
          r(i) = chem_net%rates(i) * tmp
        else
          r(i) = chem_net%rates(i) * (1D0 - exp(-tmp))
        end if
      case (63) ! gA + gA -> gB
        ! dt(N(H2)) = k_HH * <H(H-1)>
        ! Moment equation:
        ! dt(N(H2)) = k_HH / (k_HH + k_desorb) * sigma * v * n(H) * N(gH)
        ! dt(X(H2)) = k_HH / (k_HH + k_desorb) * sigma * v * n(H) * X(gH)
        ! dt(X(H2)) = k_HH / (k_HH + k_desorb) * sigma * v * X(H) * X(gH) * n_dust / D2G
        ! Rate equation:
        ! dt(X(H2)) = k_HH * X(H)**2 / D2G
        if (chem_net%reac_names(1, i) .eq. 'gH') then
          if (chemsol_params%H2_form_use_moeq) then
            i1 = chem_species%idx_gasgrain_counterpart(chem_net%reac(1, i))
            r(i) = chem_net%rates(i) * y(i1) * y(chem_net%reac(1, i))
            !ydot(i1) = ydot(i1) - rtmp ! It's like H + gH -> gH2. So dt(H) -= rtmp, dt(gH) += rtmp
            !ydot(chem_net%reac(1, i)) = ydot(chem_net%reac(1, i)) + rtmp
          else
            r(i) = chem_net%rates(i) * y(chem_net%reac(1, i)) * y(chem_net%reac(1, i))
          end if
        else
          r(i) = chem_net%rates(i) * y(chem_net%reac(1, i)) * y(chem_net%reac(1, i))
        end if
      case default
        cycle
    end select
  end do
end subroutine chem_ode_f_alt



subroutine chem_make_sparse_structure
  integer i, j, k
  !
  chemsol_params%NEQ = chem_species%nSpecies + 1
  !
  allocate(chemsol_stor%sparseMaskJac(chemsol_params%NEQ, &
    chemsol_params%NEQ))
  chemsol_stor%sparseMaskJac = .FALSE.
  do i=1, chem_net%nReactions
    do j=1, chem_net%n_reac(i)
      do k=1, chem_net%n_reac(i)
        chemsol_stor%sparseMaskJac &
          (chem_net%reac(k, i), chem_net%reac(j, i)) = .TRUE.
      end do
      do k=1, chem_net%n_prod(i)
        chemsol_stor%sparseMaskJac &
          (chem_net%prod(k, i), chem_net%reac(j, i)) = .TRUE.
      end do
    end do
  end do
  do i=1, chemsol_params%NEQ
    chemsol_stor%sparseMaskJac(i, chem_species%nSpecies + 1) = .true.
  end do
  do i=1, chem_idx_some_spe%nItem
    chemsol_stor%sparseMaskJac(chem_species%nSpecies + 1, chem_idx_some_spe%idx(i)) = .true.
  end do
  chemsol_params%NNZ = count(chemsol_stor%sparseMaskJac)
end subroutine chem_make_sparse_structure


! Getting the time taken and few other
! parameters after first step is complete.
subroutine chem_evol_solve_prepare_run_once
  !
  chemsol_params%dt_first_step0 = chemsol_params%dt_first_step
  chemsol_params%t_max0 = chemsol_params%t_max
  !
  chemsol_params%n_record = ceiling( &
    log((chemsol_params%t_max-chemsol_params%t0) / &
        chemsol_params%dt_first_step * &
        (chemsol_params%ratio_tstep - 1D0) + 1D0) &
    / &
    log(chemsol_params%ratio_tstep)) + 1
  !
  if (.not. allocated(chemsol_stor%y)) then
    allocate(&
      chemsol_stor%y(chemsol_params%NEQ), &
      chemsol_stor%y0(chemsol_params%NEQ), &
      chemsol_stor%ydot(chemsol_params%NEQ), &
      chemsol_stor%RTOLs(chemsol_params%NEQ), &
      chemsol_stor%ATOLs(chemsol_params%NEQ), &
      chemsol_stor%touts(chemsol_params%n_record), &
      chemsol_stor%record(chemsol_params%NEQ, chemsol_params%n_record))
  end if
end subroutine chem_evol_solve_prepare_run_once



! To get the total time after a number of
! steps and few pther parameters.
subroutine chem_evol_solve_prepare_ongoing
  ! n_record may change
  integer n_rec_prev
  !
  n_rec_prev = chemsol_params%n_record
  !
  chemsol_params%n_record = ceiling( &
    log((chemsol_params%t_max-chemsol_params%t0) / &
        chemsol_params%dt_first_step * &
        (chemsol_params%ratio_tstep - 1D0) + 1D0) &
    / &
    log(chemsol_params%ratio_tstep)) + 1
  !
  if (allocated(chemsol_stor%touts) .and. &
      (n_rec_prev .lt. chemsol_params%n_record)) then
    deallocate(chemsol_stor%touts, chemsol_stor%record)
  end if
  if (.not. allocated(chemsol_stor%touts)) then
    allocate(&
      chemsol_stor%touts(chemsol_params%n_record), &
      chemsol_stor%record(chemsol_params%NEQ, chemsol_params%n_record))
  end if
end subroutine chem_evol_solve_prepare_ongoing



! Storing the mentioned parameters from solver.
subroutine chem_prepare_solver_storage
  integer i, j, k
  chemsol_params%LRW = &
    20 + 4 * chemsol_params%NNZ + 28 * chemsol_params%NEQ
    !20 + chemsol_params%NEQ * (12 + 1) &
    !+ 3 * chemsol_params%NEQ + 4 * chemsol_params%NNZ &
    !+ 2 * chemsol_params%NEQ + chemsol_params%NNZ &
    !+ 10 * chemsol_params%NEQ
  chemsol_params%LIW = 31 + chemsol_params%NEQ + chemsol_params%NNZ
  allocate( &
    chemsol_stor%RWORK(chemsol_params%LRW), &
    chemsol_stor%IWORK(chemsol_params%LIW))
  chemsol_stor%RWORK(5:10) = 0D0
  chemsol_stor%IWORK(5:10) = 0
  chemsol_stor%IWORK(5) = 5
  chemsol_stor%IWORK(6) = chemsol_params%mxstep_per_interval
  chemsol_stor%IWORK(31) = 1
  chemsol_stor%IWORK(7) = 1
  chemsol_stor%RWORK(7) = 0D0
  k = 1
  do i=1, chemsol_params%NEQ
    do j=1, chemsol_params%NEQ
      if (chemsol_stor%sparseMaskJac(j, i)) then
        chemsol_stor%IWORK(31 + chemsol_params%NEQ + k) = j
        k = k + 1
      end if
    end do
    chemsol_stor%IWORK(31+i) = k
  end do
  deallocate(chemsol_stor%sparseMaskJac)
end subroutine chem_prepare_solver_storage



! Simply neutralizes the initial conditions
! and load the initial abundances.
subroutine chem_load_initial_abundances
  integer fU, i, ios
  character(len=const_len_init_abun_file_row) str
  double precision totH_ini
  call openFileSequentialRead(fU, &
    combine_dir_filename(chemsol_params%chem_files_dir, &
    chemsol_params%filename_initial_abundances), 999, getu=1)
  chemsol_stor%y(1:chem_species%nSpecies) = 0D0
  do
    read(fU, FMT='(A)', IOSTAT=ios) str
    if (ios .NE. 0) then
      exit
    end if
    do i=1, chem_species%nSpecies
      if (trim(str(1:const_len_species_name)) .EQ. chem_species%names(i)) then
        read(str(const_len_species_name+1:const_len_init_abun_file_row), &
          '(F16.0)') chemsol_stor%y(i)
        exit
      end if
    end do
  end do
  close(fU)
  !
  ! Neutralize the initial condition
  chemsol_stor%y(chem_idx_some_spe%i_E) = &
    chemsol_stor%y(chem_idx_some_spe%i_E) + &
      sum(chemsol_stor%y(1:chem_species%nSpecies) * &
          dble(chem_species%elements(1, :)))
  if (chemsol_stor%y(chem_idx_some_spe%i_E) .lt. 0D0) then
    write(*,'(A)') 'In chem_load_initial_abundances:'
    write(*,'(A)') 'Cannot neutralize the initial condition!'
    write(*,'(A, ES12.3/)') 'X(E-) = ', &
        chemsol_stor%y(chem_idx_some_spe%i_E)
    call error_stop()
  end if
  !
  totH_ini = dot_product(chem_species%elements(4,:), &
                         chemsol_stor%y(1:chem_species%nSpecies))
  write(*, '(/A, F16.10)') 'Initial total H abundance:', totH_ini
  write(*, '(A/)') 'Renormalize to 1.'
  chemsol_stor%y(1:chem_species%nSpecies) = &
    chemsol_stor%y(1:chem_species%nSpecies) / totH_ini
  !
  ! Make a copy for possible later use
  chemsol_stor%y0(1:chem_species%nSpecies) = &
    chemsol_stor%y(1:chem_species%nSpecies)
end subroutine chem_load_initial_abundances

! Loads the enthalpies for available species.
subroutine chem_load_species_enthalpies
  integer j, i1, fU, ios
  double precision dblTmp
  character(Len=32) FMTstr, strTMP
  character(Len=128) str_disp
  character commentChar
  character(LEN=const_len_species_name) nameSpecies_tmp
  ! The output enthalpies are in K.
  if (allocated(chem_species%enthalpies)) then
    deallocate(chem_species%enthalpies, chem_species%hasEnthalpy)
  end if
  allocate(chem_species%enthalpies(chem_species%nSpecies), &
           chem_species%hasEnthalpy(chem_species%nSpecies))
  chem_species%enthalpies = dblNaN()
  chem_species%hasEnthalpy = .false.
  i1 = 0
  commentChar = '!'
  if (IsWordChar(chemsol_params%filename_species_enthalpy(1:1))) then
    write (FMTstr, FMT= '("(", "A", I2, ", F", I1, ".0)")') &
      const_len_species_name, 9
    CALL openFileSequentialRead(fU, &
        combine_dir_filename(chemsol_params%chem_files_dir, &
        chemsol_params%filename_species_enthalpy), 999999, getu=1)
    do
      read (UNIT=fU, FMT='(A32)', IOSTAT=ios) strTMP
      if (ios .NE. 0) then
        exit
      end if
      if ((strTMP(1:1) .EQ. commentChar) .OR. &
          (strTMP(1:1) .EQ. ' ')) then
        cycle
      end if
      read (strTMP, FMT=FMTstr, IOSTAT=ios) nameSpecies_tmp, dblTmp
      if (ios .NE. 0) then
        write (*, *) 'Error in importing enthalpies: ios = ', ios
        call error_stop()
      end if
      do j=1, chem_species%nSpecies
        if (trim(chem_species%names(j)) .EQ. trim(nameSpecies_tmp)) then
          ! Convert from kJ/mol to K to erg.
          chem_species%enthalpies(j) = dblTmp * 1D3 / phy_IdealGasConst_SI * phy_kBoltzmann_CGS
          chem_species%hasEnthalpy(j) = .true.
          i1 = i1 + 1
          exit
        end if
      end do
    end do
    close (UNIT=fU, IOSTAT=ios, STATUS='KEEP')
    write(str_disp, '("! ", I5, A, I5, A)') &
      i1, ' of ', chem_species%nSpecies, ' species have enthalpy.'
    call display_string_both(str_disp, chemsol_params%fU_log)
  end if
end subroutine chem_load_species_enthalpies


! To get the heat from reactions using enthaplies.
subroutine chem_get_reaction_heat
  integer i, j, k
  double precision, dimension(:), allocatable :: htmp
  integer, dimension(:), allocatable :: itmp
  character(Len=128) str_disp
  double precision htmp1
  logical hasHeat
  !
  if (allocated(chem_net%heat)) then
    deallocate(chem_net%heat, chem_net%iReacWithHeat)
  end if
  !
  allocate(htmp(chem_net%nReactions), &
           itmp(chem_net%nReactions))
  !
  k = 0
  do i=1, chem_net%nReactions
    if (chem_net%itype(i) .ne. 5) then
      cycle
    end if
    if ((chem_net%ctype(i) .eq. 'RA') .or. &
        (chem_net%ctype(i) .eq. 'RR')) then
      cycle
    end if
    !
    hasHeat = .true.
    htmp1 = 0D0
    do j=1, chem_net%n_reac(i)
      if (.not. chem_species%hasEnthalpy(chem_net%reac(j,i))) then
        hasHeat = .false.
        exit
      end if
      htmp1 = htmp1 + chem_species%enthalpies(chem_net%reac(j,i))
    end do
    if (.not. hasHeat) then
      cycle
    end if
    do j=1, chem_net%n_prod(i)
      if (.not. chem_species%hasEnthalpy(chem_net%prod(j,i))) then
        hasHeat = .false.
        exit
      end if
      htmp1 = htmp1 - chem_species%enthalpies(chem_net%prod(j,i))
    end do
    if (hasHeat .and. (abs(htmp1) .gt. 1D-50)) then
      k = k + 1
      itmp(k) = i
      htmp(k) = htmp1
    end if
  end do
  !
  if (k .ge. 1) then
    chem_net%nReacWithHeat = k
    allocate(chem_net%heat(k), &
             chem_net%iReacWithHeat(k))
    chem_net%heat = htmp(1:k)
    chem_net%iReacWithHeat = itmp(1:k)
  end if
  write(str_disp, '("! ", I5, A, I5, A)') &
    k, ' of ', chem_net%nReactions, ' reactions have heat.'
  call display_string_both(str_disp, chemsol_params%fU_log)
  ! do i=1, chem_net%nReacWithHeat
  !   j = chem_net%iReacWithHeat(i)
  !   write(*,'(6A,ES16.6E4)') chem_net%reac_names(1:2, j), &
  !     chem_net%prod_names(1:4, j), chem_net%heat(i)
  ! end do
  !
  deallocate(itmp, htmp)
end subroutine chem_get_reaction_heat


! To load the abundances
! of different elements
pure subroutine get_elemental_abundance(y, n, eleAb, nEle)
  integer, intent(in) :: n, nEle
  double precision, intent(in), dimension(n) :: y
  double precision, intent(out), dimension(nEle) :: eleAb
  integer i, j
  !
  eleAb = 0D0
  do j=1, chem_species%nSpecies
    do i=1, const_nElement
      eleAb(i) = eleAb(i) + y(j) * dble(chem_species%elements(i, j))
    end do
  end do
end subroutine get_elemental_abundance

! using charge to rectify them
subroutine rectify_abundances(n, y)
  integer, intent(in) :: n
  double precision, intent(inout), dimension(n) :: y
  integer iG0, iGM, iGP
  double precision totalCharge
  integer, parameter :: nMaxIterRecti=10
  integer i
  !
  !iG0 = chem_idx_some_spe%i_Grain0
  !iGM = chem_idx_some_spe%i_GrainM
  !iGP = chem_idx_some_spe%i_GrainP
  !if (iG0 .gt. 0) then
  !  y(iG0) = chem_params%ratioDust2HnucNum
  !  do i=1, nMaxIterRecti
  !    y(iGP) = get_species_producing_rate(n, y, iGP) / &
  !                  get_species_destructing_coeff(n, y, iGP)
  !    y(iGM) = get_species_producing_rate(n, y, iGM) / &
  !                  get_species_destructing_coeff(n, y, iGM)
  !    y(iG0) = get_species_producing_rate(n, y, iG0) / &
  !                  get_species_destructing_coeff(n, y, iG0)
  !  end do
  !end if
  !
  totalCharge = sum(y(1:chem_species%nSpecies) * &
                    dble(chem_species%elements(1, :)))
  y(chem_idx_some_spe%i_E) = y(chem_idx_some_spe%i_E) + totalCharge
  if (y(chem_idx_some_spe%i_E) .lt. 0D0) then
    write(*, '(A)') 'Cannot neutralize!'
    write(*, '(2(A, ES16.6))') &
      'X(charge)= ', totalCharge, 'X(E)= ', y(chem_idx_some_spe%i_E)
  end if
end subroutine rectify_abundances


function get_species_producing_rate(n, y, iSpe) result(r)
  double precision r
  integer, intent(in) :: n, iSpe
  double precision, intent(inout), dimension(n) :: y
  integer j, ireac
  r = 0D0
  do j=1, chem_species%produ(iSpe)%nItem
    ireac = chem_species%produ(iSpe)%list(j)
    r = r + dble(chem_species%produ(iSpe)%n_repeat(j)) * &
            get_reac_rate(n, y, ireac)
  end do
end function get_species_producing_rate


function get_species_destructing_coeff(n, y, iSpe) result(r)
  double precision r
  integer, intent(in) :: n, iSpe
  double precision, intent(inout), dimension(n) :: y
  integer j, ireac
  r = 0D0
  do j=1, chem_species%destr(iSpe)%nItem
    ireac = chem_species%destr(iSpe)%list(j)
    r = r + dble(chem_species%destr(iSpe)%n_repeat(j)) * &
            get_reac_rate(n, y, ireac, iSpeDiff=iSpe)
  end do
end function get_species_destructing_coeff


function get_reac_rate(n, y, iReac, iSpeDiff) result(r)
  double precision r
  integer, intent(in) :: n, iReac
  double precision, intent(inout), dimension(n) :: y
  integer, intent(in), optional :: iSpeDiff
  double precision tmp, tmp1, tmp2, del
  r = 0D0
  if (present(iSpeDiff)) then
    del = y(iSpeDiff) * 1D-6 + 1D-30
    tmp = y(iSpeDiff)
    if (chem_net%n_reac(iReac) .eq. 1) then
      tmp1 = chem_net%rates(iReac) * y(chem_net%reac(1, iReac))
      y(iSpeDiff) = y(iSpeDiff) + del
      tmp2 = chem_net%rates(iReac) * y(chem_net%reac(1, iReac))
      r = (tmp2 - tmp1) / del
    else if (chem_net%n_reac(iReac) .eq. 2) then
      tmp1 = chem_net%rates(iReac) * &
            y(chem_net%reac(1, iReac)) * y(chem_net%reac(2, iReac))
      y(iSpeDiff) = y(iSpeDiff) + del
      tmp2 = chem_net%rates(iReac) * &
            y(chem_net%reac(1, iReac)) * y(chem_net%reac(2, iReac))
      r = (tmp2 - tmp1) / del
    end if
    y(iSpeDiff) = tmp
  else
    if (chem_net%n_reac(iReac) .eq. 1) then
      r = chem_net%rates(iReac) * y(chem_net%reac(1, iReac))
    else if (chem_net%n_reac(iReac) .eq. 2) then
      r = chem_net%rates(iReac) * &
            y(chem_net%reac(1, iReac)) * y(chem_net%reac(2, iReac))
    end if
  end if
end function get_reac_rate


end module chemistry
