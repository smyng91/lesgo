!!
!!  Copyright (C) 2009-2013  Johns Hopkins University
!!
!!  This file is part of lesgo.
!!
!!  lesgo is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License as published by
!!  the Free Software Foundation, either version 3 of the License, or
!!  (at your option) any later version.
!!
!!  lesgo is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with lesgo.  If not, see <http://www.gnu.org/licenses/>.
!!

module param
  use types, only : rprec, point3D_t
  $if ($MPI)
  use mpi
  $endif
  implicit none
  $if ($MPI)
!  include 'mpif.h'
  $endif
  save

  private rprec
  public

!*******************************************************************************
!***  ALL NON-PARAMETER DEFINITIONS READ BY INPUT FILE MUST BE INITIALIZED   ***
!*******************************************************************************

!---------------------------------------------------
! GLOBAL PARAMETERS
!---------------------------------------------------  
  integer, parameter :: CHAR_BUFF_LENGTH = 1024 ! Default size of string buffers with unknown length
  character(*), parameter :: PATH = './'
  character(*), parameter :: checkpoint_file = path // 'vel.out'
  character(*), parameter :: checkpoint_tavg_file = path // 'tavg.out'
  $if($OUTPUT_EXTRA) 
  character(*), parameter :: checkpoint_tavg_sgs_file = path // 'tavg_sgs.out'
  $endif
  character(*), parameter :: checkpoint_spectra_file = path // 'spectra.out'

!---------------------------------------------------
! MPI PARAMETERS
!---------------------------------------------------

  $if ($MPI)
  integer :: status(MPI_STATUS_SIZE)
  logical, parameter :: USE_MPI = .true.
  integer, parameter :: lbz = 0  ! overlap level for MPI transfer
  $else
  logical, parameter :: USE_MPI = .false.
  integer, parameter :: lbz = 1  ! no overlap level necessary
  $endif

  !--this stuff must be defined, even if not using MPI
  ! Setting defaults for ones that can be used even with no MPI
  integer :: nproc = 1 !--this must be 1 if no MPI
  integer :: rank = 0   !--init to 0 (so its defined, even if no MPI)
  integer :: coord = 0  !--same here

  character (8) :: chcoord  !--holds character representation of coord
  integer :: ierr
  integer :: comm
  integer :: up, down
  integer :: global_rank
  integer :: MPI_RPREC, MPI_CPREC
  integer, allocatable, dimension(:) ::  rank_of_coord, coord_of_rank
  integer :: jzmin, jzmax  ! levels that "belong" to this processor, set w/ grid

!---------------------------------------------------
! COMPUTATIONAL DOMAIN PARAMETERS
!---------------------------------------------------  

  integer, parameter :: iBOGUS = -1234567890  !--NOT a new Apple product
  real (rprec), parameter :: BOGUS = -1234567890._rprec
  real(rprec),parameter::pi=3.1415926535897932384626433_rprec

  integer :: Nx=64, Ny=64, Nz=64
  integer :: nz_tot = 64
  integer :: nx2, ny2
  integer :: lh, ld, lh_big, ld_big

  ! this value is dimensional [m]:
  real(rprec) :: z_i = 1000.0_rprec
    
  ! these values should be non-dimensionalized by z_i: 
  ! set as multiple of BL height (z_i) then non-dimensionalized by z_i
  logical :: uniform_spacing = .false.
  real(rprec) :: L_x = 2.0*pi, L_y=2.0*pi, L_z=1.0_rprec

  ! these values are also non-dimensionalized by z_i:
  real(rprec) :: dx, dy, dz
  
!---------------------------------------------------
! MODEL PARAMETERS
!---------------------------------------------------   

  ! Model type: 1->Smagorinsky; 2->Dynamic; 3->Scale dependent
  !             4->Lagrangian scale-sim   5-> Lagragian scale-dep
  integer :: sgs_model=5, wall_damp_exp=2

  ! timesteps between dynamic Cs updates           
  integer :: cs_count = 5

  ! When to start dynamic Cs calculations
  integer :: DYN_init = 100
  
  ! Cs is the Smagorinsky Constant
  ! Co and wall_damp_exp are used in the mason model for smagorisky coeff
  real(rprec) :: Co = 0.16_rprec
  
  ! test filter type: 1->cut off 2->Gaussian 3->Top-hat
  integer :: ifilter = 1

  ! u_star=0.45 m/s if coriolis_forcing=.FALSE. and =ug if coriolis_forcing=.TRUE.
  real(rprec) :: u_star = 0.45_rprec

  ! von Karman constant     
  real(rprec) :: vonk = 0.4_rprec
  
  ! Coriolis stuff
  ! coriol=non-dim coriolis parameter,
  ! ug=horiz geostrophic vel, vg=transverse geostrophic vel
  logical :: coriolis_forcing = .true. 
  real(rprec) :: coriol = 1.0e-4_rprec, ug=1.0_rprec, vg=0.0_rprec

  ! nu_molec is dimensional m^2/s
  real(rprec) :: nu_molec = 1.14e-5_rprec
  
  ! mode limiting options for RNL    !!jb
  logical :: molec=.false., sgs=.true., dns_bc=.false.
  logical :: kx_limit=.false.
  integer :: kx_allow = 1
  logical :: use_ml=.false.
  integer :: ml_start = 1000, ml_end = 1000000

!---------------------------------------------------
! TIMESTEP PARAMETERS
!---------------------------------------------------   

  integer :: nsteps = 50000
  ! -- Maximum runtime in seconds. Simulation will exit if exceeded. (disabled by default)
  integer :: runtime = -1 

  logical :: use_cfl_dt = .false.  
  real(rprec) :: cfl = 0.05
  real(rprec) :: dt_f=2.0e-4, cfl_f=0.05

  real(rprec) :: dt = 2.0e-4_rprec
  real(rprec) :: dt_dim
  
  ! time advance parameters (Adams-Bashforth, 2nd order accurate)
  real(rprec) :: tadv1, tadv2
  
  logical :: cumulative_time = .true.
  character (*), parameter :: fcumulative_time = path // 'total_time.dat'
  
  integer :: jt=0                 ! Local time counter
  integer :: jt_total=0           ! Global time counter
  real(rprec) :: total_time, total_time_dim
  
!---------------------------------------------------
! BOUNDARY/INITIAL CONDITION PARAMETERS
!---------------------------------------------------  

  ! initu = true to read from a file; false to create with random noise
  logical :: initu = .false.
  ! initlag = true to initialize cs, FLM & FMM; false to read from vel.out
  logical :: inilag = .true.

  ! lbc: lower boundary condition:  0 - stress free, 1 - wall 
  ! NOTE: the upper boundary condition is implicitly stress free
  integer :: lbc_mom = 1
  
  ! lower boundary condition, roughness length
  real(rprec) :: zo = 0.0001_rprec ! nondimensional

  ! prescribed inflow:   
  logical :: inflow = .false.
  ! if inflow is true the following should be set:
    ! position of right end of fringe region, as a fraction of L_x
    real(rprec) :: fringe_region_end  = 1.0_rprec
    ! length of fringe region as a fraction of L_x
    real(rprec) :: fringe_region_len = 0.125_rprec

    ! Use uniform inflow instead of concurrent precursor inflow
    logical :: uniform_inflow = .false.
      real(rprec) :: inflow_velocity = 1.0_rprec

  ! if true, imposes a pressure gradient in the x-direction to force the flow
  logical :: use_mean_p_force = .true.
  ! Specify whether mean_p_force should be evaluated as 1/L_z
  logical :: eval_mean_p_force = .false. 
  real(rprec) :: mean_p_force = 1.0_rprec
  
!---------------------------------------------------
! DATA OUTPUT PARAMETERS
!---------------------------------------------------

  ! how often to display stdout
  integer :: wbase = 100

  ! how often to write ke to check_ke.out
  integer :: nenergy = 100

  ! how often to display Lagrangian CFL condition of 
  ! dynamic SGS models
  integer :: lag_cfl_count = 1000

  ! Flags for controling checkpointing data
  logical :: checkpoint_data = .false.
  integer :: checkpoint_nskip = 10000

  ! records time-averaged data to files ./output/*_avg.dat
  logical :: tavg_calc = .false.
  integer :: tavg_nstart = 1, tavg_nend = 50000, tavg_nskip = 100

  ! turns instantaneous velocity recording on or off
  logical :: point_calc = .false.
  integer :: point_nstart=1, point_nend=50000, point_nskip=10
  integer :: point_nloc=1
  type(point3D_t), allocatable, dimension(:) :: point_loc

  ! domain instantaneous output
  logical :: domain_calc=.false.
  integer :: domain_nstart=10000, domain_nend=50000, domain_nskip=10000
  
  ! x-plane instantaneous output
  logical :: xplane_calc=.false.
  integer :: xplane_nstart=10000, xplane_nend=50000, xplane_nskip=10000
  integer :: xplane_nloc=1
  real(rprec), allocatable, dimension(:) :: xplane_loc

  ! y-plane instantaneous output
  logical :: yplane_calc=.false.
  integer :: yplane_nstart=10000, yplane_nend=50000, yplane_nskip=10000
  integer :: yplane_nloc=1
  real(rprec), allocatable, dimension(:) :: yplane_loc

  ! z-plane instantaneous output
  logical :: zplane_calc=.false.
  integer :: zplane_nstart=10000, zplane_nend=50000, zplane_nskip=10000
  integer :: zplane_nloc=1
  real(rprec), allocatable, dimension(:) :: zplane_loc

  logical :: spectra_calc=.false.
  integer :: spectra_nstart=10000, spectra_nend=50000, spectra_nskip=100
  integer :: spectra_nloc=1
  real(rprec), allocatable, dimension(:) :: spectra_loc

  ! Outputs histograms of {Cs^2, Tn, Nu_t, ee} for z-plane locations given below
  logical :: sgs_hist_calc = .false.
  logical :: sgs_hist_cumulative = .false.
  integer :: sgs_hist_nstart = 5000, sgs_hist_nskip = 2
  integer :: sgs_hist_nloc = 3
  real(rprec), allocatable, dimension(:) :: sgs_hist_loc   ! size=sgs_hist_nloc

  ! Limits for Cs^2 (square of Smagorinsky coefficient)
  real(rprec) :: cs2_bmin = 0.0_rprec, cs2_bmax = 0.15_rprec
  integer :: cs2_nbins = 1000

  ! Limits for Tn (Lagrangian time-averaging timescale, models 4,5 only)
  real(rprec) :: tn_bmin = 0.0_rprec, tn_bmax = 1.0_rprec
  integer :: tn_nbins = 1000

  ! Limits for Nu_t (turbulent eddy viscosity)
  real(rprec) :: nu_bmin = 0.0_rprec, nu_bmax = 0.03_rprec
  integer :: nu_nbins = 1000

  ! Limits for ee (error for Germano identity)
  real(rprec) :: ee_bmin = 0.0_rprec, ee_bmax = 100.0_rprec
  integer :: ee_nbins = 10000

end module param
