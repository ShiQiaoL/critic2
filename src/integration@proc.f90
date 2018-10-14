! Copyright (c) 2007-2018 Alberto Otero de la Roza <aoterodelaroza@gmail.com>,
! Ángel Martín Pendás <angel@fluor.quimica.uniovi.es> and Víctor Luaña
! <victor@fluor.quimica.uniovi.es>. 
!
! critic2 is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or (at
! your option) any later version.
! 
! critic2 is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
! 
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

submodule (integration) proc
  use param, only: mmlen
  implicit none

  !xx! private procedures
  ! subroutine int_output_header(bas,res)
  ! subroutine int_output_fields(bas,res)
  ! subroutine int_reorder_gridout(ff,bas)
  ! subroutine intgrid_fields(bas,res)
  ! subroutine intgrid_deloc_wannier(bas,res)
  ! subroutine write_sijchk(sijfname,nbnd,nbndw,nwan,nmo,nlat,nspin,nattr,sij)
  ! subroutine write_fachk(fafname,nbnd,nbndw,nwan,nmo,nlat,nspin,nattr,fa)
  ! function read_chk_header(fname,nbnd,nbndw,nwan,nmo,nlat,nspin,nattr)
  ! subroutine read_sijchk_body(sijfname,sij)
  ! subroutine read_fachk_body(fafname,fa)
  ! subroutine calc_sij_wannier(fid,wancut,useu,imtype,natt1,iatt,ilvec,idg1,xattr,dat,luevc,luevc_ibnd,sij)
  ! function quadpack_f(x,unit,xnuc) result(res)
  ! subroutine int_output_multipoles(bas,res)
  ! subroutine int_output_deloc_wannier(bas,res)
  ! subroutine assign_strings(i,icp,usesym,scp,sncp,sname,smult,sz)
  ! subroutine int_gridbasins(bas)
  ! subroutine int_cubew(bas)
  ! subroutine unpackidx(idx,io,jo,ko,bo,nmo,nbnd,nwan)
  ! subroutine packidx(io,jo,ko,bo,idx,nmo,nbnd,nwan)

  ! grid integration types
  integer, parameter :: imtype_bader = 1
  integer, parameter :: imtype_yt = 2

contains

  !> Driver for the integration in grids
  module subroutine intgrid_driver(line)
    use bader, only: bader_integrate
    use yt, only: yt_integrate, yt_weights, ytdata, ytdata_clean
    use systemmod, only: sy
    use fieldmod, only: type_grid
    use grid3mod, only: grid3
    use global, only: eval_next, dunit0, iunit, iunitname0
    use tools_io, only: ferror, faterr, lgetword, equal, isexpression_or_word, uout,&
       string, fclose, isinteger
    use types, only: basindat, int_result

    character*(*), intent(in) :: line

    real*8, parameter :: ratom_def0 = 1d0

    character(len=:), allocatable :: word
    integer :: n(3), ntot
    integer :: lp, lp2
    logical :: ok, nonnm, noatoms
    real*8 :: ratom_def
    type(grid3) :: faux
    type(int_result), allocatable :: res(:)
    type(basindat) :: bas
    
    ! only grids
    if (.not.sy%isinit) then
       call ferror("intgrid_integrate","system not initialized",faterr)
       return
    end if
    if (.not.associated(sy%c)) then
       call ferror("intgrid_integrate","system does not have crystal",faterr)
       return
    end if
    if (.not.sy%goodfield(sy%iref)) then
       call ferror("intgrid_integrate","reference field not initalized",faterr)
       return
    end if
    if (sy%f(sy%iref)%type /= type_grid) then
       call ferror("intgrid_driver","BADER/YT can only be used with grids",faterr,line,syntax=.true.)
       return
    end if
    if (sy%npropi <= 0) then
       call ferror("intgrid_driver","no integrable properties",faterr,line,syntax=.true.)
       return
    end if

    ! method and header
    lp = 1
    word = lgetword(line,lp)
    if (equal(word,"yt")) then
       bas%imtype = imtype_yt
    elseif (equal(word,"bader")) then
       bas%imtype = imtype_bader
    else
       call ferror("intgrid_driver","wrong method",faterr,line,syntax=.true.)
       return
    endif

    ! parse the input
    ratom_def = ratom_def0
    nonnm = .true.
    noatoms = .false.
    bas%wcube = .false.
    bas%ndrawbasin = -1
    bas%basinfmt = "obj"
    bas%expr = ""
    do while(.true.)
       word = lgetword(line,lp)
       if (equal(word,"nnm")) then
          nonnm = .false.
       elseif (equal(word,"noatoms")) then
          noatoms = .true.
       elseif (equal(word,"ratom")) then
          nonnm = .false.
          ok = eval_next(ratom_def,line,lp)
          if (.not.ok) then
             call ferror("intgrid_driver","wrong RATOM keyword",faterr,line,syntax=.true.)
             return
          end if
          ratom_def = ratom_def / dunit0(iunit)
       elseif (equal(word,"wcube")) then
          bas%wcube = .true.
       elseif (equal(word,"basins")) then
          lp2 = lp
          word = lgetword(line,lp)
          if (equal(word,"obj")) then
             bas%basinfmt = "obj"
          elseif (equal(word,"ply")) then
             bas%basinfmt = "ply"
          elseif (equal(word,"off")) then
             bas%basinfmt = "off"
          else
             lp = lp2
             bas%basinfmt = "obj"
          end if
          ok = isinteger(bas%ndrawbasin,line,lp)
          if (.not.ok) &
             bas%ndrawbasin = 0
       elseif (equal(word,"discard")) then
          ok = isexpression_or_word(bas%expr,line,lp)
          if (.not. ok) then
             call ferror("intgrid_driver","wrong DISCARD keyword",faterr,line,syntax=.true.)
             return
          end if
       elseif (len_trim(word) > 0) then
          call ferror("intgrid_driver","Unknown extra keyword",faterr,line,syntax=.true.)
          return
       else
          exit
       end if
    end do

    ! field number of grid points
    bas%n = sy%f(sy%iref)%grid%n
    ntot = n(1)*n(2)*n(3)

    ! distance for atom assignment
    if (noatoms) then
       bas%atexist = .false.
       bas%ratom = ratom_def
    elseif (nonnm) then
       bas%atexist = .true.
       bas%ratom = 1d40
    else
       bas%atexist = .true.
       bas%ratom = ratom_def
    end if

    ! prepare the array for the basin field
    allocate(bas%f(bas%n(1),bas%n(2),bas%n(3)))
    if (sy%f(sy%iref)%usecore) then
       call sy%c%promolecular_grid(faux,sy%f(sy%iref)%grid%n,sy%f(sy%iref)%zpsp)
       bas%f = sy%f(sy%iref)%grid%f + faux%f
       call faux%end()
    else
       bas%f = sy%f(sy%iref)%grid%f
    end if

    ! call the integration method
    bas%luw = 0
    if (bas%imtype == imtype_bader) then
       write (uout,'("* Henkelman et al. integration ")')
       write (uout,'("  Please cite: ")')
       write (uout,'("    G. Henkelman, A. Arnaldsson, and H. Jonsson, Comput. Mater. Sci. 36, 254-360 (2006).")')
       write (uout,'("    E. Sanville, S. Kenny, R. Smith, and G. Henkelman, J. Comput. Chem. 28, 899-908 (2007).")')
       write (uout,'("    W. Tang, E. Sanville, and G. Henkelman, J. Phys.: Condens. Matter 21, 084204 (2009).")')
       write (uout,'("+ Distance atomic assignment (",A,"): ",A)') iunitname0(iunit),&
          string(max(bas%ratom,0d0),'e',decimal=4)
       if (len_trim(bas%expr) > 0) &
          write (uout,'("+ Discard attractor expression: ",A)') trim(bas%expr)
       call bader_integrate(sy,bas)
       write (uout,'("+ Attractors in BADER: ",A)') string(bas%nattr)
    elseif (bas%imtype == imtype_yt) then
       write (uout,'("* Yu-Trinkle integration ")')
       write (uout,'("  Please cite: ")')
       write (uout,'("  Min Yu, Dallas Trinkle, J. Chem. Phys. 134 (2011) 064111.")')
       write (uout,'("+ Distance atomic assignment (",A,"): ",A)') iunitname0(iunit),&
          string(max(bas%ratom,0d0),'e',decimal=4)
       if (len_trim(bas%expr) > 0) &
          write (uout,'("+ Discard attractor expression: ",A)') trim(bas%expr)
       call yt_integrate(sy,bas)
       write (uout,'("+ Attractors in YT: ",A)') string(bas%nattr)
    endif

    ! Reorder the attractors
    call int_reorder_gridout(sy%f(sy%iref),bas) 
    write (uout,'("+ Attractors after reordering: ",A)') string(bas%nattr)
    write (uout,*)

    ! Write weight cubes
    call int_cubew(bas)

    ! Bains plotting
    call int_gridbasins(bas)

    ! deallocate the basin field
    deallocate(bas%f)

    ! Prepare for the calculation of properties
    allocate(res(sy%npropi))
    write (uout,'("+ Integrating atomic properties"/)') 

    ! Integrate scalar fields and multipoles
    call intgrid_fields(bas,res)

    ! localization and delocalization indices - wannier
    call intgrid_deloc_wannier(bas,res)

    ! header for integration output
    write (uout,*)
    call int_output_header(bas,res)

    ! output integrated scalar field properties
    call int_output_fields(bas,res)

    ! output multipoles
    call int_output_multipoles(bas,res)

    ! localization and delocalization indices, wannier
    call int_output_deloc_wannier(bas,res)

    ! clean up YT weight file
    if (bas%imtype == imtype_yt) then
       call fclose(bas%luw)
    endif

  end subroutine intgrid_driver

  !> Do a radial numerical quadrature on the given ray, between the
  !> selected radii and return the properties. The r^2 factor is
  !> included.
  module subroutine int_radialquad(x,theta,phi,r0,rend,lprop,abserr,neval,iaserr,ierr)
    use systemmod, only: sy
    use quadpack, only: dqags, dqng, dqag
    use global, only: int_radquad_type, int_gauleg, int_radquad_nr, int_qags, &
       int_radquad_relerr, int_qng, int_radquad_abserr, int_qag, int_iasprec
    use tools_math, only: gauleg
    real*8, intent(in) :: x(3)  !< The center of the basin (cartesian coords)
    real*8, intent(in) :: theta !< Polar angle of the ray
    real*8, intent(in) :: phi   !< Azimuthal angle or the ray
    real*8, intent(in) :: r0    !< Left limit of the radial interval
    real*8, intent(in) :: rend  !< Right limit of the radial interval
    real*8, intent(out) :: lprop(sy%npropi) !< The integrated properties
    real*8, intent(out) :: abserr !< Estimated absolute error
    integer, intent(out) :: neval !< Number of evaluations of grdall
    real*8, intent(out) :: iaserr(sy%npropi) !< Estimated IAS precision error
    integer, intent(out) :: ierr

    integer :: k, isign
    real*8 :: unit(3), xaux(3), r1, r2
    real*8, dimension(sy%npropi) :: atprop
    integer :: ier
    ! quadpack internals
    integer, parameter :: limit = 10000
    integer, parameter :: lenw = 4*limit
    integer :: iwork(limit)
    real*8 :: work(lenw)
    integer :: last, key
    ! radial integration
    real*8, allocatable :: rpoints(:), rweights(:)

    unit = (/ sin(theta) * cos(phi),&
              sin(theta) * sin(phi),&
              cos(theta) /)
    ierr = 0

    if (rend > r0) then
       r1 = r0
       r2 = rend
       isign = 1
    else
       r1 = rend
       r2 = r0
       isign = -1
    end if

    select case(INT_radquad_type)
    case (INT_gauleg)
       ! allocate and set radial nodes
       allocate(rpoints(INT_radquad_nr),rweights(INT_radquad_nr))
       call gauleg(r1,r2,rpoints,rweights,INT_radquad_nr)

       ! do the quadrature
       lprop = 0d0
       do k = 1, INT_radquad_nr
          xaux = x + rpoints(k) * unit
          call sy%grdall(xaux,atprop)
          lprop = lprop + rpoints(k)**2 * rweights(k) * atprop
       end do
       lprop = lprop * isign
       lprop(1) = isign * (r2**3 - r1**3) / 3d0 ! hardwire volume
       abserr = 0d0
       neval = INT_radquad_nr

       ! deallocate
       deallocate(rpoints,rweights)

    case (INT_qags)
       call dqags(quadpack_f,unit,x,r0,rend,INT_radquad_abserr,&
          INT_radquad_relerr,lprop,abserr,neval,&
          ier,limit,lenw,last,iwork,work)
       ierr = max(ierr,ier)

    case (INT_qng)
       call dqng(quadpack_f,unit,x,r0,rend,INT_radquad_abserr,&
          INT_radquad_relerr,lprop,abserr,neval,ier)
       ierr = max(ierr,ier)

    case (INT_qag)
       if (INT_radquad_nr >= 30) then
          key = 6
       else if (INT_radquad_nr >= 25) then
          key = 5
       else if (INT_radquad_nr >= 20) then
          key = 4
       else if (INT_radquad_nr >= 15) then
          key = 3
       else if (INT_radquad_nr >= 10) then
          key = 2
       else
          key = 1
       end if
       call dqag(quadpack_f,unit,x,r0,rend,INT_radquad_abserr,&
          INT_radquad_relerr,key,lprop,abserr,neval,&
          ier,limit,lenw,last,iwork,work)
       ierr = max(ierr,ier)
    end select

    ! IAS precision error
    xaux = x + rend * unit
    call sy%grdall(xaux,atprop)
    iaserr = abs(atprop * rend**2 * INT_iasprec)
    neval = neval + 1

  end subroutine int_radialquad

  !> Sum the gauss-legendre 2d (ntheta * nphi) quadrature. The srf
  !> minisurface contains the rays generated by gauleg_nodes, with
  !> radii corresponding to the IAS. ntheta and nphi. The resulting
  !> integrated properties are returned in the lprop vector. abserr is
  !> the integrated error of the radial quadrature. iaserr is the error
  !> caused by IAS inaccuracies.  neval is the number of evaluations of
  !> grdall used. rbeta is a reference radius (beta-sphere).
  module subroutine gauleg_mquad(srf,ntheta,nphi,rbeta,lprop,abserr,neval,iaserr)
    use systemmod, only: sy
    use surface, only: minisurf
    use tools_math, only: gauleg
    use tools_io, only: ferror, warning, uout
    use param, only: pi
    type(minisurf), intent(inout) :: srf !< Surface representing the basin
    integer, intent(in) :: ntheta !< Number of polar points
    integer, intent(in) :: nphi   !< Number of azimuthal points
    real*8, intent(in) :: rbeta   !< Beta-spehre radius
    real*8, intent(out) :: lprop(sy%npropi) !< Properties vector
    real*8, intent(out) :: abserr !< Integrated radial quad. error
    integer, intent(out) :: neval !< Number of evaluations
    real*8, intent(out) :: iaserr(sy%npropi) !< Integrated IAS precision error

    integer :: i, j, v, leval
    real*8 :: rprop(sy%npropi), pprop(sy%npropi)
    real*8 :: rerr, perr, riaserr(sy%npropi), piaserr(sy%npropi)
    integer :: realnphi, ierr, err, vidx(ntheta,nphi+1)
    ! Nodes and weights
    real*8, allocatable, dimension(:) :: tpoints
    real*8, allocatable, dimension(:) :: tweights
    real*8, allocatable, dimension(:) :: ppoints
    real*8, allocatable, dimension(:) :: pweights

    allocate(tpoints(ntheta),tweights(ntheta))
    allocate(ppoints(nphi+1),pweights(nphi+1))
    ppoints = 0d0
    pweights = 0d0

    ! initialize
    neval = 0
    lprop = 0d0
    abserr = 0d0
    iaserr = 0d0
    err = 0

    ! set theta-nodes
    call gauleg(0d0,pi,tpoints,tweights,ntheta)

    ! fill idx array
    v = 0
    do i = 1, ntheta
       do j = 1, int(nphi*abs(sin(tpoints(i))))+1
          v = v + 1
          vidx(i,j) = v
       end do
    end do

    !$omp parallel do reduction(+:neval,abserr) reduction(max:err) private(&
    !$omp realnphi,pprop,rprop,perr,piaserr,leval,ierr,rerr,&
    !$omp riaserr,v) firstprivate(ppoints,pweights) schedule(guided)
    do i = 1, ntheta
       realnphi = int(nphi*abs(sin(tpoints(i))))+1
       call gauleg(0d0,2d0*pi,ppoints,pweights,realnphi)
       pprop = 0d0
       perr = 0d0
       piaserr = 0d0
       do j = 1, realnphi
          v = vidx(i,j)
          call int_radialquad(srf%n,srf%th(v),srf%ph(v),rbeta,srf%r(v),&
             rprop,rerr,leval,riaserr,ierr)
          pprop = pprop + rprop * pweights(j)
          perr = perr + rerr * pweights(j)
          piaserr = piaserr + riaserr * pweights(j)
          neval = neval + leval
          err = max(err,ierr)
       end do
       !$omp critical (sum_gauleg_mquad)
       lprop = lprop + sin(srf%th(v)) * tweights(i) * pprop
       iaserr = iaserr + sin(srf%th(v)) * tweights(i) * piaserr
       !$omp end critical (sum_gauleg_mquad)
       abserr = abserr + sin(srf%th(v)) * tweights(i) * perr
    end do
    !$omp end parallel do

    deallocate(tpoints,tweights,ppoints,pweights)

    if (err /= 0) then
       call ferror('gauleg_mquad','Radial integration had non-zero error code',warning)
       write (uout,'(a,I2)') " ier = ", err
       write (uout,'(a)') " Check the routine documentation for more info."
    end if

  end subroutine gauleg_mquad

  !> Sum the Lebedev 2d quadrature with npts points. The srf
  !> minisurface contains the rays generated by lebedev_nodes, with
  !> radii corresponding to the IAS. ntheta and nphi. The resulting
  !> integrated properties are returned in the lprop vector. abserr is
  !> the integrated error of the radial quadrature. iaserr is the error
  !> caused by IAS inaccuracies.  neval is the number of evaluations of
  !> grdall used. rbeta is a reference radius (beta-sphere).
  module subroutine lebedev_mquad(srf,npts,rbeta,lprop,abserr,neval,iaserr)
    use systemmod, only: sy
    use surface, only: minisurf
    use tools_math, only: select_lebedev
    use tools_io, only: uout, ferror, warning
    type(minisurf), intent(inout) :: srf !< Surface representing the basin
    integer, intent(in) :: npts   !< Number of points
    real*8, intent(in) :: rbeta   !< Beta-spehre radius
    real*8, intent(out) :: lprop(sy%npropi) !< Properties vector
    real*8, intent(out) :: abserr !< Integrated radial quad. error
    integer, intent(out) :: neval !< Number of evaluations
    real*8, intent(out) :: iaserr(sy%npropi) !< Integrated IAS precision error

    integer :: i, v, leval
    real*8 :: rprop(sy%npropi)
    real*8 :: rerr, riaserr(sy%npropi)
    integer :: ierr, err
    ! Nodes and weights
    real*8 :: xleb(5810)
    real*8 :: yleb(5810)
    real*8 :: zleb(5810)
    real*8 :: wleb(5810)

    call select_lebedev(npts,xleb,yleb,zleb,wleb)

    neval = 0
    lprop = 0d0
    abserr = 0d0
    iaserr = 0d0
    v = 0
    err = 0

    !$omp parallel do private(rprop,rerr,leval,riaserr,ierr) reduction(+:abserr,neval)&
    !$omp reduction(max:err) schedule(guided)
    do i = 1, npts
       call int_radialquad(srf%n,srf%th(i),srf%ph(i),rbeta,srf%r(i),&
          rprop,rerr,leval,riaserr,ierr)
       !$omp critical (sum_lebedev_mquad)
       lprop = lprop + rprop * wleb(i)
       iaserr = iaserr + riaserr * wleb(i)
       !$omp end critical (sum_lebedev_mquad)
       abserr = abserr + rerr  * wleb(i)
       neval = neval + leval
       err = max(err,ierr)
    end do
    !$omp end parallel do

    if (err /= 0) then
       call ferror('lebedev_mquad','Radial integration had non-zero error code',warning)
       write (uout,'(a,I2)') " ier = ", err
       write (uout,'(a)') " Check the routine documentation for more info."
    end if

  end subroutine lebedev_mquad

  !xx! private procedures

  !> Write the header for the integration results section to the output. Includes
  !> a list of properties integrated in the basins. bas = integration driver
  !> data, res(1:npropi) = results. If nomol0, prevent the output of molecular
  !> properties. If usesym0, use multiplicities.
  module subroutine int_output_header(bas,res,nomol0,usesym0)
    use systemmod, only: sy, itype_v, itype_expr, itype_mpoles, itype_names
    use global, only: iunitname0, iunit, dunit0
    use tools_io, only: uout, string, ioj_left, ioj_center, ioj_right
    use types, only: basindat, int_result
    type(basindat), intent(in) :: bas
    type(int_result), intent(in) :: res(:)
    logical, intent(in), optional :: nomol0
    logical, intent(in), optional :: usesym0

    integer :: i, j, k, fid
    character(len=:), allocatable :: saux, label, cini, itaux
    character(len=:), allocatable :: sncp, scp, sname, sz, smult
    real*8 :: x(3), xcm(3)
    integer, allocatable :: idxmol(:,:)
    logical :: nomol, usesym

    nomol = .false.
    if (present(nomol0)) nomol = nomol0
    usesym = .false.
    if (present(usesym0)) usesym = usesym0

    ! List of integrable properties accepted/rejected and why some
    ! were rejected
    write (uout,'("* List of properties integrated in the attractor basins")')
    write (uout,'("+ The ""Label"" entries will be used to identify the integrable")')
    write (uout,'("  in the tables of integrated atomic properties. The entries with")')
    write (uout,'("  an ""x"" will not be integrated.")')
    write (uout,'("# id    Label      fid  Field       Additional")')
    do i = 1, sy%npropi
       fid = sy%propi(i)%fid
       if (.not.res(i)%done) then
          label = "--inactive--"
          cini = "x "
          saux = "Reason: " // string(res(i)%reason)
       else
          label = sy%propi(i)%prop_name
          cini = "  "
       end if
       if (sy%propi(i)%itype == itype_v) then
          if (res(i)%done) saux = ""
          itaux = "--"
       elseif (sy%propi(i)%itype == itype_expr) then
          if (res(i)%done) saux = "expr = " // string(sy%propi(i)%expr)
          itaux = "--"
       elseif (sy%propi(i)%itype == itype_mpoles) then
          if (res(i)%done) saux = "Lmax = " // string(sy%propi(i)%lmax)
          itaux = string(fid)
       else
          if (res(i)%done) saux = ""
          itaux = string(fid)
       end if

       write (uout,'(A2,99(A,X))') cini, string(i,4,ioj_left), string(label,12,ioj_center), &
          string(itaux,2,ioj_right), string(itype_names(sy%propi(i)%itype),12,ioj_left),&
          string(saux)
    end do
    write (uout,*)

    ! key
    write (uout,'("* Key for the interpretation of table headings")')
    write (uout,'("# Id = attractor identifier")')
    write (uout,'("# cp/at = critical point/atom from the complete CP/atom list")')
    write (uout,'("# (lvec) = lattice translation from CP/atom to the main cell''s representative")')
    write (uout,'("# ncp/nat = critical point/atom from the non-equivalent CP/atom list")')
    write (uout,'("# Name = atomic name")')
    write (uout,'("# Z = atomic number")')
    write (uout,'("# Position = atomic position")')
    write (uout,'("# Mol = molecule identifier (see corresponding table above)")')
    write (uout,'("# Volume = volume of the reference field basins.")')
    write (uout,'("# Pop (population) = the reference field integrated in its own basins.")')
    write (uout,'("# Lap = Laplacian of the reference field integrated in the reference field basins.")')
    write (uout,'("# $xxx = field xxx integrated in the basins of the reference field.")')
    write (uout,*)

    ! List of attractors and positions
    write (uout,'("* List of attractors integrated")')
    if (.not.sy%c%ismolecule) then
       write (uout,'("# Id   cp   ncp   Name  Z   mult           Position (cryst.) ")')
    else
       write (uout,'("# Id   cp   ncp   Name  Z   mult           Position (",A,") ")') iunitname0(iunit)
    endif
    do i = 1, bas%nattr
       call assign_strings(i,bas%icp(i),usesym,scp,sncp,sname,smult,sz)
       if (.not.sy%c%ismolecule) then
          x = bas%xattr(:,i)
       else
          x = (sy%c%x2c(bas%xattr(:,i)) + sy%c%molx0) * dunit0(iunit)
       endif
       write (uout,'(2X,99(A,X))') string(i,4,ioj_left), scp, sncp, sname, sz, &
          smult, (string(x(j),'f',12,7,4),j=1,3)
    end do
    write (uout,*)

    ! List of molecules and positions
    if (.not.nomol .and. .not.sy%c%ismolecule .and. all(sy%c%mol(1:sy%c%nmol)%discrete)) then
       allocate(idxmol(2,bas%nattr))
       ! Assign attractors to molecules
       idxmol = 0
       do i = 1, bas%nattr
          jlo: do j = 1, sy%c%nmol
             do k = 1, sy%c%mol(j)%nat
                if (bas%icp(i) == sy%c%mol(j)%at(k)%cidx) then
                   idxmol(1,i) = j
                   idxmol(2,i) = k
                   exit jlo
                end if
             end do
          end do jlo
       end do

       ! List of molecules and associated attractors
       write (uout,'("* List of molecules integrated")')
       write (uout,'("+ Id   at (lvec)   nat    Name  Z              Position (cryst.) ")')
       do i = 1, sy%c%nmol
          xcm = sy%c%mol(i)%cmass()
          xcm = sy%c%c2x(xcm)
          ! name the molecule
          write (uout,'("# Molecule ",A," with ",A," atoms at ",3(A,X))') string(i), &
             string(sy%c%mol(i)%nat), (string(xcm(j),'f',10,6,3),j=1,3)

          ! Atomic composition
          do j = 1, bas%nattr
             if (idxmol(1,j) /= i) cycle
             call assign_strings(j,bas%icp(j),usesym,scp,sncp,sname,smult,sz)
             x = sy%c%mol(idxmol(1,j))%at(idxmol(2,j))%x
             write (uout,'(A,X,A,"(",2(A,X),A,")",X,99(A,X))') & 
                string(j,4,ioj_left), scp, (string(sy%c%mol(idxmol(1,j))%at(idxmol(2,j))%lvec(k),2,ioj_right),k=1,3),&
                sncp, sname, sz, (string(x(k),'f',12,7,4),k=1,3)
          end do
       end do
       write (uout,*)
       deallocate(idxmol)
    end if

  end subroutine int_output_header

  !> Write to output the result of integrating scalar fields in the
  !> atomic basins. bas = integration driver data, res(1:npropi) =
  !> results. If nomol0, prevent the output of molecular
  !> properties. If usesym0, use multiplicities.
  subroutine int_output_fields(bas,res,nomol0,usesym0)
    use systemmod, only: sy
    use tools_io, only: uout, string, ioj_left, ioj_center
    use types, only: basindat, int_result, out_field
    type(basindat), intent(in) :: bas
    type(int_result), intent(in) :: res(:)
    logical, intent(in), optional :: nomol0
    logical, intent(in), optional :: usesym0

    integer, parameter :: ncols = 5

    integer :: i, j, k
    integer :: ip, iplast, ipmax
    integer :: nacprop(ncols)
    real*8 :: sump(sy%npropi), xmult
    character(len=:), allocatable :: sncp, scp, sname, sz, smult
    integer, allocatable :: idxmol(:,:)
    logical :: nomol, usesym

    nomol = .false.
    if (present(nomol0)) nomol = nomol0
    usesym = .false.
    if (present(usesym0)) usesym = usesym0

    ! Integrated scalar fields, atomic properties
    write (uout,'("* Integrated atomic properties")')
    write (uout,'("# (See key above for interpretation of column headings.)")')
    iplast = 0
    do ip = 0, (count(res(1:sy%npropi)%outmode == out_field)-1)/ncols
       ! show only the properties that have been done
       nacprop = 0
       ipmax = 0
       do i = iplast+1, sy%npropi
          if (res(i)%done .and. res(i)%outmode == out_field) then
             ipmax = ipmax + 1
             nacprop(ipmax) = i
          end if
          if (ipmax == ncols) exit
       end do
       if (ipmax == 0) exit
       iplast = nacprop(ipmax)

       ! Table header for this set of properties
       write (uout,'("# Integrable properties ",A," to ",A)') string(nacprop(1)), string(nacprop(ipmax))
       write (uout,'("# Id   cp   ncp   Name  Z   mult ",5(A,X))') &
          (string(sy%propi(nacprop(j))%prop_name,15,ioj_center),j=1,ipmax)

       ! Table rows
       sump = 0d0
       do i = 1, bas%nattr
          call assign_strings(i,bas%icp(i),usesym,scp,sncp,sname,smult,sz)
          if (bas%icp(i) > 0 .and. usesym) then
             xmult = sy%f(sy%iref)%cp(sy%f(sy%iref)%cpcel(bas%icp(i))%idx)%mult
          else
             xmult = 1
          endif
          ! add to the sum
          do j = 1, ipmax
             sump(nacprop(j)) = sump(nacprop(j)) + res(nacprop(j))%psum(i) * xmult
          end do
          ! table entry
          write (uout,'(2X,99(A,X))') string(i,4,ioj_left), scp, sncp, sname, sz, smult, &
             (string(res(nacprop(j))%psum(i),'e',15,8,4),j=1,ipmax)
       end do
       write (uout,'(32("-"),99(A))') ("----------------",j=1,ipmax)
       write (uout,'(2X,"Sum                           ",99(A,X))') &
          (string(sump(nacprop(j)),'e',15,8,4),j=1,ipmax)
       write (uout,*)
    end do

    if (.not.nomol .and. .not.sy%c%ismolecule .and. all(sy%c%mol(1:sy%c%nmol)%discrete)) then
       allocate(idxmol(2,bas%nattr))
       ! Assign attractors to molecules
       idxmol = 0
       do i = 1, bas%nattr
          jlo: do j = 1, sy%c%nmol
             do k = 1, sy%c%mol(j)%nat
                if (bas%icp(i) == sy%c%mol(j)%at(k)%cidx) then
                   idxmol(1,i) = j
                   idxmol(2,i) = k
                   exit jlo
                end if
             end do
          end do jlo
       end do
       
       ! List of integrated properties in the molecules
       write (uout,'("* Integrated molecular properties")')
       write (uout,'("# (See key above for interpretation of column headings.)")')
       iplast = 0
       do ip = 0, (count(res(1:sy%npropi)%outmode == out_field)-1)/ncols
          ! show only the properties that have been done
          nacprop = 0
          ipmax = 0
          do i = iplast+1, sy%npropi
             if (res(i)%done .and. res(i)%outmode == out_field) then
                ipmax = ipmax + 1
                nacprop(ipmax) = i
             end if
             if (ipmax == ncols) exit
          end do
          if (ipmax == 0) exit
          iplast = nacprop(ipmax)

          ! Table header for this set of properties
          write (uout,'("# Integrable properties ",A," to ",A)') string(nacprop(1)), string(nacprop(ipmax))
          write (uout,'("# Mol ",5(A,X))') (string(sy%propi(nacprop(j))%prop_name,15,ioj_center),j=1,ipmax)

          ! Table rows
          do k = 1, sy%c%nmol+1
             if (k == sy%c%nmol+1 .and. all(idxmol > 0)) cycle
             sump = 0d0
             do i = 1, bas%nattr
                if (idxmol(1,i) /= mod(k,sy%c%nmol+1)) cycle
                ! add to the sum
                if (bas%icp(i) > 0 .and. usesym) then
                   xmult = sy%f(sy%iref)%cp(sy%f(sy%iref)%cpcel(bas%icp(i))%idx)%mult
                else
                   xmult = 1
                endif
                do j = 1, ipmax
                   sump(nacprop(j)) = sump(nacprop(j)) + res(nacprop(j))%psum(i) * xmult
                end do
             end do
             ! table entry
             if (k < sy%c%nmol+1) then
                write (uout,'(2X,99(A,X))') string(k,4,ioj_left), (string(sump(nacprop(j)),'e',15,8,4),j=1,ipmax)
             else
                write (uout,'(2X,99(A,X))') "????", (string(sump(nacprop(j)),'e',15,8,4),j=1,ipmax)
             end if
          end do
          write (uout,*) 
       end do
       deallocate(idxmol)
    end if

  end subroutine int_output_fields

  !> The attractors coming out of YT and BADER are not in order
  !> compatible with the crystal structure. Reorder them, including
  !> the weights of the YT. On output, gives the identity of the
  !> attractors (icp) in the complete CP list. bas contains the
  !> integration information.
  subroutine int_reorder_gridout(ff,bas)
    use fieldmod, only: field, type_grid
    use tools_io, only: ferror, faterr, fopen_scratch, fclose
    use types, only: realloc, basindat
    use param, only: icrd_crys
    type(field), intent(inout) :: ff
    type(basindat), intent(inout) :: bas

    integer :: i, j
    integer, allocatable :: idgaux(:,:,:), assigned(:)
    integer :: nn, nid, nattr0, luw2, n(3), nbasin, nvec
    real*8 :: dist
    integer, allocatable :: nlo(:), ibasin(:), ibasin2(:), iio(:), inear(:,:)
    real*8, allocatable :: fnear(:,:), xattr(:,:)

    if (ff%type /= type_grid) &
       call ferror("int_reorder_gridout","BADER/YT can only be used with grids",faterr)
    n = ff%grid%n

    ! reorder the maxima and assign maxima to atoms according to ratom
    if (allocated(bas%icp)) deallocate(bas%icp)
    allocate(bas%icp(bas%nattr),xattr(3,bas%nattr),assigned(bas%nattr))
    bas%icp = 0
    assigned = 0
    nattr0 = bas%nattr
    ! assign attractors to atoms
    if (bas%atexist) then
       do i = 1, nattr0
          nid = ff%c%identify_atom(bas%xattr(:,i),icrd_crys,distmax=bas%ratom)
          if (nid > 0) then
             assigned(i) = nid
          else
             ! maybe the closest point is a known nnm
             call ff%nearest_cp(bas%xattr(:,i),nid,dist,type=ff%typnuc)
             if (dist < bas%ratom) then
                assigned(i) = nid
             end if
          end if
       end do
    end if
    ! create the new known attractors in the correct order
    bas%nattr = 0
    do i = 1, ff%ncpcel
       if (any(assigned == i)) then
          bas%nattr = bas%nattr + 1
          bas%icp(bas%nattr) = i
          xattr(:,bas%nattr) = ff%cpcel(i)%x
       endif
    end do
    ! the rest are their own nnm, add them to the CP list, accumulate
    ! using a radius equal to ratom.
    do i = 1, nattr0
       if (assigned(i) > 0) cycle
       bas%nattr = bas%nattr + 1
       assigned(i) = bas%nattr
       bas%icp(bas%nattr) = 0

       nn = 1
       xattr(:,bas%nattr) = bas%xattr(:,i)
       do j = i+1, nattr0
          if (assigned(j) > 0) cycle
          if (ff%c%are_lclose(bas%xattr(:,i),bas%xattr(:,j),bas%ratom)) then
             nn = nn + 1
             assigned(j) = bas%nattr
          end if
       end do
       call ff%addcp(ff%c%x2c(xattr(:,bas%nattr)),1d-2,1d-1,2d-1,ff%typnuc)
    end do
    deallocate(bas%xattr)

    ! update the idg
    allocate(idgaux(size(bas%idg,1),size(bas%idg,2),size(bas%idg,3)))
    idgaux = bas%idg
    do i = 1, nattr0
       if (assigned(i) /= i) then
          where (bas%idg == i)
             idgaux = assigned(i)
          end where
       end if
    end do
    call move_alloc(idgaux,bas%idg)

    ! update the weights the YT file
    if (bas%luw /= 0) then
       ! read all the info from the scratch file
       rewind(bas%luw)
       read (bas%luw) nbasin, nn, nvec
       if (nattr0 /= nbasin) &
          call ferror('int_reorder_gridout','inconsistent number of attractors in yt checkpoint',faterr)
       allocate(ibasin(nn),ibasin2(nn),nlo(nn),inear(nvec,nn),fnear(nvec,nn),iio(nn))
       read (bas%luw) nlo
       read (bas%luw) ibasin
       read (bas%luw) iio
       read (bas%luw) inear
       read (bas%luw) fnear

       ! build a new ibasin array
       ibasin2 = ibasin
       do i = 1, nattr0
          where (ibasin == i)
             ibasin2 = assigned(i)
          end where
       end do

       ! write the new data to a new scratch file
       luw2 = fopen_scratch()
       write (luw2) nattr0, nn, nvec
       write (luw2) nlo 
       write (luw2) ibasin2
       write (luw2) iio 
       write (luw2) inear
       write (luw2) fnear
       call flush(luw2)
       rewind(luw2)
       call fclose(bas%luw)
       bas%luw = luw2
       deallocate(nlo,ibasin,ibasin2,iio,inear,fnear)
    end if
    deallocate(assigned)
    
    if (allocated(bas%xattr)) deallocate(bas%xattr)
    call realloc(xattr,3,bas%nattr)
    call move_alloc(xattr,bas%xattr)

  end subroutine int_reorder_gridout

  !> Integrate scalar fields in atomic basins. bas = integration driver
  !> data, res(1:npropi) = results.
  subroutine intgrid_fields(bas,res)
    use yt, only: ytdata, ytdata_clean, yt_weights
    use systemmod, only: sy, itype_v, itype_f, itype_fval, itype_gmod, &
       itype_lap, itype_lapval, itype_mpoles, itype_expr
    use grid3mod, only: grid3
    use fieldmod, only: type_grid
    use tools_math, only: tosphere, genrlm_real
    use tools_io, only: uout, string
    use types, only: basindat, int_result, out_mpoles, out_field
    type(basindat), intent(in) :: bas
    type(int_result), intent(inout) :: res(:)
    
    integer :: i1, i2, i3
    integer :: i, k, m, fid, ntot, lmax, ix
    real*8, allocatable :: fint(:,:,:), w(:,:,:), rrlm(:)
    type(grid3) :: faux
    logical :: ok, fillgrd
    logical :: plmask(sy%npropi), first
    real*8 :: lprop(sy%npropi), x(3), x2(3), padd, p(3), dv(3), r
    real*8 :: tp(2)
    type(ytdata) :: dat

    first = .true.
    ntot = bas%n(1)*bas%n(2)*bas%n(3)
    do k = 1, sy%npropi
       if (res(k)%done) cycle
       if (.not.sy%propi(k)%used) cycle
       if (sy%propi(k)%itype == itype_v) then
          ! integrate the basin volume
          if (allocated(res(k)%psum)) deallocate(res(k)%psum)
          allocate(res(k)%psum(bas%nattr))
          res(k)%psum = 0d0
          write (uout,'("+ Integrated property (number ",A,"): ",A)') string(k), string(sy%propi(k)%prop_name)

          if (first) call run_first_pass()

          ! compute weights and integrate the scalar field properties
          !$omp parallel do private(padd) firstprivate(w) schedule(dynamic)
          do i = 1, bas%nattr
             if (bas%imtype == imtype_yt) then
                call yt_weights(din=dat,idb=i,w=w)
             end if
             if (bas%imtype == imtype_bader) then
                padd = count(bas%idg == i) * sy%c%omega / real(ntot,8)
             else
                padd = sum(w) * sy%c%omega / real(ntot,8)
             endif
             !$omp critical (accum)
             res(k)%psum(i) = res(k)%psum(i) + padd
             !$omp end critical (accum)
          end do
          !$omp end parallel do
          res(k)%outmode = out_field
       elseif (sy%propi(k)%itype == itype_f.or.sy%propi(k)%itype == itype_fval.or.&
          sy%propi(k)%itype == itype_gmod.or.sy%propi(k)%itype == itype_lap .or.&
          sy%propi(k)%itype == itype_lapval.or.sy%propi(k)%itype == itype_expr.or.&
          sy%propi(k)%itype == itype_mpoles) then
          ! integrate scalar fields other than volume
          fid = sy%propi(k)%fid
          if (.not.sy%goodfield(fid)) then
             res(k)%reason = "unknown or invalid field"
             cycle
          end if
          write (uout,'("+ Integrated property (number ",A,"): ",A)') string(k), string(sy%propi(k)%prop_name)

          if (first) call run_first_pass()

          if (.not.allocated(fint)) &
             allocate(fint(bas%n(1),bas%n(2),bas%n(3)))
          
          ! copy the grid if it is available
          fillgrd = .false.
          ok = (sy%f(fid)%type == type_grid)
          if (ok) ok = all(sy%f(fid)%grid%n == bas%n)
          if (ok) then
             if (sy%propi(k)%itype == itype_fval .or.&
                sy%propi(k)%itype == itype_f.and..not.sy%f(fid)%usecore.or.&
                sy%propi(k)%itype == itype_mpoles.and..not.sy%f(fid)%usecore) then
                fint = sy%f(fid)%grid%f
             elseif (sy%propi(k)%itype == itype_lapval .or.&
                sy%propi(k)%itype == itype_lap.and..not.sy%f(fid)%usecore) then
                call faux%laplacian(sy%f(fid)%grid,sy%c%m_x2c)
                fint = faux%f
             elseif (sy%propi(k)%itype == itype_gmod.and..not.sy%f(fid)%usecore) then
                call faux%gradrho(sy%f(fid)%grid,sy%c%m_x2c)
                fint = faux%f
             else
                fillgrd = .true.
             end if
             call faux%end()
          else
             fillgrd = .true.
          endif

          ! otherwise generate the field on the grid
          if (fillgrd) then
             plmask = .false.
             plmask(k) = .true.
             !$omp parallel do private(x,x2,lprop) schedule(dynamic)
             do i1 = 1, bas%n(1)
                x(1) = real(i1-1,8) / bas%n(1)
                do i2 = 1, bas%n(2)
                   x(2) = real(i2-1,8) / bas%n(2)
                   do i3 = 1, bas%n(3)
                      x(3) = real(i3-1,8) / bas%n(3)
                      x2 = sy%c%x2c(x)
                      call sy%grdall(x2,lprop,plmask)
                      !$omp critical (write)
                      fint(i1,i2,i3) = lprop(k)
                      !$omp end critical (write)
                   end do
                end do
             end do
             !$omp end parallel do
          end if
          
          if (.not.sy%propi(k)%itype == itype_mpoles) then
             ! all types of integration except for multipoles
             if (allocated(res(k)%psum)) deallocate(res(k)%psum)
             allocate(res(k)%psum(bas%nattr))
             res(k)%psum = 0d0

             ! compute weights and integrate the scalar field properties
             !$omp parallel do private(padd) firstprivate(w) schedule(dynamic)
             do i = 1, bas%nattr
                if (bas%imtype == imtype_yt) then
                   call yt_weights(din=dat,idb=i,w=w)
                end if
                if (bas%imtype == imtype_bader) then
                   padd = sum(fint,bas%idg==i) * sy%c%omega / real(ntot,8)
                else
                   padd = sum(w * fint) * sy%c%omega / real(ntot,8)
                endif
                !$omp critical (accum)
                res(k)%psum(i) = res(k)%psum(i) + padd
                !$omp end critical (accum)
             end do
             !$omp end parallel do
             res(k)%outmode = out_field
          else
             ! multipoles
             ! allocate temporary space
             lmax = sy%propi(k)%lmax
             allocate(rrlm((lmax+1)*(lmax+1)))
             rrlm = 0d0

             ! allocate result space
             if (allocated(res(k)%mpole)) deallocate(res(k)%mpole)
             allocate(res(k)%mpole((lmax+1)*(lmax+1),bas%nattr))
             res(k)%mpole = 0d0

             if (bas%imtype == imtype_bader) then
                ! calcualate the multipoles, with bader
                !$omp parallel do private(p,ix,dv,r,tp) firstprivate(rrlm) schedule(dynamic)
                do i1 = 1, bas%n(1)
                   p(1) = real(i1-1,8)
                   do i2 = 1, bas%n(2)
                      p(2) = real(i2-1,8)
                      do i3 = 1, bas%n(3)
                         p(3) = real(i3-1,8)
                         ix = bas%idg(i1,i2,i3)
                         dv = p/real(bas%n,8) - bas%xattr(:,ix)
                         call sy%c%shortest(dv,r)
                         call tosphere(dv,r,tp)
                         call genrlm_real(lmax,r,tp,rrlm)

                         !$omp critical (accum)
                         res(k)%mpole(:,ix) = res(k)%mpole(:,ix) + rrlm * fint(i1,i2,i3)
                         !$omp end critical (accum)
                      end do
                   end do
                end do
                !$omp end parallel do
             else
                w = 0d0
                !$omp parallel do private(p,dv,r,tp) firstprivate(w,rrlm) schedule(dynamic)
                do m = 1, bas%nattr
                   call yt_weights(din=dat,idb=m,w=w)
                   do i1 = 1, bas%n(1)
                      do i2 = 1, bas%n(2)
                         do i3 = 1, bas%n(3)
                            if (abs(w(i1,i2,i3)) < 1d-15) cycle
                            p = real((/i1-1,i2-1,i3-1/),8)
                            dv = p/real(bas%n,8) - bas%xattr(:,m)
                            call sy%c%shortest(dv,r)
                            call tosphere(dv,r,tp)
                            call genrlm_real(lmax,r,tp,rrlm)

                            !$omp critical (accum)
                            res(k)%mpole(:,m) = res(k)%mpole(:,m) + rrlm * fint(i1,i2,i3) * w(i1,i2,i3)
                            !$omp end critical (accum)
                         end do
                      end do
                   end do
                end do
                !$omp end parallel do
                res(k)%outmode = out_mpoles
             endif
             res(k)%mpole = res(k)%mpole * sy%c%omega / real(ntot,8)
             deallocate(rrlm)
          end if
       else
          ! none of the above
          cycle
       end if
       res(k)%done = .true.
       res(k)%reason = ""
    end do

    ! clean up
    if (allocated(fint)) deallocate(fint)
    if (allocated(w)) deallocate(w)
    if (bas%imtype == imtype_yt) then
       call ytdata_clean(dat)
    end if
    
  contains
    subroutine run_first_pass()
      ! YT, get the data
      if (bas%imtype == imtype_yt) then
         allocate(w(bas%n(1),bas%n(2),bas%n(3)))
         w = 0d0
         call yt_weights(luw=bas%luw,dout=dat)
      end if

      ! do not run this again
      first = .false.
    end subroutine run_first_pass

  end subroutine intgrid_fields

  !> Calculate localization and delocalization indices using maximally
  !> localized Wannier functions. bas = integration driver data,
  !> res(1:npropi) = results.
  subroutine intgrid_deloc_wannier(bas,res)
    use yt, only: yt_weights, ytdata, ytdata_clean
    use systemmod, only: sy, itype_deloc, itype_deloc_sijchk, itype_deloc_fachk
    use fieldmod, only: type_grid, type_wfn
    use crystalmod, only: crystal
    use crystalseedmod, only: crystalseed
    use global, only: fileroot
    use tools_io, only: uout, string, fopen_read, fclose, fopen_write, ferror, faterr
    use tools_math, only: matinv
    use types, only: basindat, realloc, int_result, out_delocwan
    type(basindat), intent(in) :: bas
    type(int_result), intent(inout) :: res(:)

    integer :: i, j, k, l, natt1
    logical :: found, calcsij, first
    integer :: luevc(2), luevc_ibnd(2)
    integer :: imo, jmo, ia, ja, ka, iba, ic, jc, kc, is
    integer :: m1, m2, m3, idx(3)
    integer :: fid, p(3)
    integer :: nwan(3), nbnd, nbndw(2), nlat, nmo, nspin, nattn, natt1
    real*8 :: x(3), xs(3), d2, fatemp
    integer, allocatable :: iatt(:), ilvec(:,:), idg1(:,:,:), imap(:,:)
    type(ytdata) :: dat
    character(len=:), allocatable :: sijfname, fafname
    real*8, allocatable :: w(:,:,:)
    integer :: ib, jb, kb, ibb
    ! real*8 :: ix1, ix2
    ! complex*16 :: aa 

    first = .true.
    do l = 1, sy%npropi
       if (res(l)%done) cycle
       if (.not.sy%propi(l)%used) cycle
       if (sy%propi(l)%itype /= itype_deloc.and.sy%propi(l)%itype /= itype_deloc_sijchk.and.sy%propi(l)%itype /= itype_deloc_fachk) cycle
       write (uout,'("+ Integrated property (number ",A,"): ",A)') string(l), string(sy%propi(l)%prop_name)
          
       ! check consistency of the field, if applicable
       ! assign checkpoints
       if (sy%propi(l)%itype == itype_deloc) then
          fid = sy%propi(l)%fid
          if (.not.sy%goodfield(fid)) then
             res(l)%reason = "unknown or invalid field"
             cycle
          end if
          sijfname = trim(sy%f(fid)%file) // "-sij"
          fafname = trim(sy%f(fid)%file) // "-fa"
       else
          sijfname = trim(fileroot) // ".chk-sij"
          fafname = trim(fileroot) // ".chk-fa"
       end if

       ! maybe we can read the Fa information and jump to the end
       if (sy%propi(l)%itype == itype_deloc_fachk) then
          if (read_chk_header(sy%propi(l)%fachkfile,nbnd,nbndw,nwan,nmo,nlat,nspin,natt1)) then
             if (natt1 == bas%nattr) then
                write (uout,'("# Reading Fa checkpoint file: ",A)') string(sy%propi(l)%fachkfile)
                if (allocated(res(l)%fa)) deallocate(res(l)%fa)
                allocate(res(l)%fa(bas%nattr,bas%nattr,nlat,nspin))
                call read_fachk_body(sy%propi(l)%fachkfile,res(l)%fa)
                goto 999
             else
                res(l)%reason = "inconsistent number of attractors in Fa checkpoint"
                cycle
             end if
          else
             res(l)%reason = "Fa checkpoint file not found"
             cycle
          end if
       else if (sy%propi(l)%itype == itype_deloc .and. sy%propi(l)%fachk) then
          if (read_chk_header(fafname,nbnd,nbndw,nwan,nmo,nlat,nspin,natt1)) then
             fid = sy%propi(l)%fid
             if (all(nbndw == sy%f(fid)%grid%qe%nbndw) .and. all(nwan == sy%f(fid)%grid%qe%nk) .and.&
                nlat == sy%f(fid)%grid%qe%nks .and. nspin == sy%f(fid)%grid%qe%nspin .and.&
                nbnd == sy%f(fid)%grid%qe%nbnd .and. natt1 == bas%nattr) then
                write (uout,'("# Reading Fa checkpoint file: ",A)') string(fafname)
                if (allocated(res(l)%fa)) deallocate(res(l)%fa)
                allocate(res(l)%fa(bas%nattr,bas%nattr,nlat,nspin))
                call read_fachk_body(fafname,res(l)%fa)
                goto 999
             end if
          end if
       end if

       ! maybe we can read the Sij information and bypass the Sij calculation
       calcsij = .true.
       if (sy%propi(l)%itype == itype_deloc_sijchk) then
          ! read the sij from a checkpoint file (without the corresponding field)
          if (read_chk_header(sy%propi(l)%sijchkfile,nbnd,nbndw,nwan,nmo,nlat,nspin,natt1)) then
             if (natt1 == bas%nattr) then
                write (uout,'("# Reading Sij checkpoint file: ",A)') string(sy%propi(l)%sijchkfile)
                if (allocated(res(l)%sijc)) deallocate(res(l)%sijc)
                allocate(res(l)%sijc(nmo,nmo,bas%nattr,nspin))
                call read_sijchk_body(sy%propi(l)%sijchkfile,res(l)%sijc)
                res(l)%nwan = nwan
                res(l)%nspin = nspin
                calcsij = .false.
             else
                res(l)%reason = "inconsistent number of attractors in Sij checkpoint"
                cycle
             end if
          else
             res(l)%reason = "Sij checkpoint file not found"
             cycle
          end if
       elseif (sy%propi(l)%itype == itype_deloc .and. sy%propi(l)%sijchk) then
          if (read_chk_header(sijfname,nbnd,nbndw,nwan,nmo,nlat,nspin,natt1)) then
             fid = sy%propi(l)%fid
             if (all(nbndw == sy%f(fid)%grid%qe%nbndw) .and. all(nwan == sy%f(fid)%grid%qe%nk) .and.&
                nlat == sy%f(fid)%grid%qe%nks .and. nspin == sy%f(fid)%grid%qe%nspin .and.&
                nbnd == sy%f(fid)%grid%qe%nbnd .and. natt1 == bas%nattr) then
                write (uout,'("# Reading Sij checkpoint file: ",A)') string(sijfname)
                if (allocated(res(l)%sijc)) deallocate(res(l)%sijc)
                allocate(res(l)%sijc(nmo,nmo,bas%nattr,nspin))
                call read_sijchk_body(sijfname,res(l)%sijc)
                calcsij = .false.
             end if
          end if
       end if ! sy%propi(l)%itype == itype_deloc, etc.

       ! assign values to some integers and check consistency of the input field
       if (sy%propi(l)%itype == itype_deloc) then
          ! check consistency of the input field
          if (sy%f(fid)%type /= type_grid) then
             if (sy%f(fid)%type /= type_wfn) &
                res(l)%reason = "cannot calculate delocalization indices with non-grid fields"
             cycle
          end if
          if (.not.sy%f(fid)%grid%isqe) then
             res(l)%reason = "QE data not available for this field"
             cycle
          end if
          if (.not.sy%f(fid)%grid%iswan .and. sy%propi(l)%useu) then
             res(l)%reason = "Wannier data not available for this field"
             cycle
          end if
          if (.not.all(sy%f(fid)%grid%n == bas%n)) then
             res(l)%reason = "Wannier and reference grids have different number of points"
             cycle
          end if
          ! assign integers
          nbnd = sy%f(fid)%grid%qe%nbnd
          nwan = sy%f(fid)%grid%qe%nk
          nlat = sy%f(fid)%grid%qe%nks
          nspin = sy%f(fid)%grid%qe%nspin
          nmo = nlat * nbnd
          if (sy%f(fid)%grid%iswan) then
             nbndw = sy%f(fid)%grid%qe%nbndw
          else
             if (nspin == 1) then
                nbndw = nbnd
             else
                nbndw(1) = nint(sum(sy%f(fid)%grid%qe%occ(:,1) / sy%f(fid)%grid%qe%wk(1)))
                nbndw(2) = nint(sum(sy%f(fid)%grid%qe%occ(:,1+nlat) / sy%f(fid)%grid%qe%wk(1)))
                ! trick to get it working without the Wannier info
                do i = 2, sy%f(fid)%grid%qe%nks
                   m1 = nint(sum(sy%f(fid)%grid%qe%occ(:,i) / sy%f(fid)%grid%qe%wk(i)))
                   m2 = nint(sum(sy%f(fid)%grid%qe%occ(:,i+nlat) / sy%f(fid)%grid%qe%wk(i)))
                   if (m1 /= nbndw(1) .or. m2 /= nbndw(2)) &
                      call ferror("intgrid_deloc_wannier","Incorrect band occupation in nspin=2 case",faterr)
                end do
                sy%f(fid)%grid%qe%nbndw = nbndw
             end if
          end if
       end if

       !!! calculate Sij !!!
       if (calcsij) then
          ! write header and allocate YT weights
          write (uout,'("# Calculating atomic overlap matrices")')

          ! get the data for YT
          if (first .and. bas%imtype == imtype_yt) then
             allocate(w(bas%n(1),bas%n(2),bas%n(3)))
             w = 0d0
             call yt_weights(luw=bas%luw,dout=dat)
             first = .false.
          end if

          ! Recalculate the number of attractors without cell translation symmetry.
          ! Calculate basin spreads.
          allocate(iatt(bas%nattr))
          nattn = bas%nattr
          do i = 1, bas%nattr
             iatt(i) = i
          enddo
          allocate(ilvec(3,bas%nattr))
          ilvec = 0
          write (uout,'(99(A,X))') "  Attractors before remapping =", string(bas%nattr)
          if (bas%imtype == imtype_bader) then
             allocate(idg1(bas%n(1),bas%n(2),bas%n(3)))
             do m3 = 1, bas%n(3)
                do m2 = 1, bas%n(2)
                   do m1 = 1, bas%n(1)
                      idg1(m1,m2,m3) = bas%idg(m1,m2,m3)
                      p = (/m1,m2,m3/)
                      x = real(p-1,8) / bas%n - bas%xattr(:,bas%idg(m1,m2,m3))
                      xs = x
                      call sy%c%shortest(xs,d2)
                      p = nint(x - sy%c%c2x(xs))
                      if (any(p /= 0)) then
                         found = .false.
                         do i = bas%nattr+1, nattn
                            if (iatt(i) == bas%idg(m1,m2,m3) .and. all(p == ilvec(:,i))) then
                               found = .true.
                               idg1(m1,m2,m3) = i
                               exit
                            end if
                         end do
                         if (.not.found) then
                            nattn = nattn + 1
                            if (nattn > size(ilvec,2)) then
                               call realloc(ilvec,3,2*nattn)
                               call realloc(iatt,2*nattn)
                            end if
                            ilvec(:,nattn) = p
                            idg1(m1,m2,m3) = nattn
                            iatt(nattn) = bas%idg(m1,m2,m3)
                         end if
                      end if
                   end do
                end do
             end do
          else
             do i = 1, bas%nattr
                call yt_weights(din=dat,idb=i,w=w)
                do m3 = 1, bas%n(3)
                   do m2 = 1, bas%n(2)
                      do m1 = 1, bas%n(1)
                         if (abs(w(m1,m2,m3)) < 1d-15) cycle
                         p = (/m1,m2,m3/)
                         x = real(p-1,8) / bas%n - bas%xattr(:,i)
                         xs = x
                         call sy%c%shortest(xs,d2)
                         p = nint(x - sy%c%c2x(xs))
                         if (any(p /= 0)) then
                            found = .false.
                            do j = bas%nattr+1, nattn
                               if (iatt(j) == i .and. all(p == ilvec(:,j))) then
                                  found = .true.
                                  exit
                               end if
                            end do
                            if (.not.found) then
                               nattn = nattn + 1
                               if (nattn > size(ilvec,2)) then
                                  call realloc(ilvec,3,2*nattn)
                                  call realloc(iatt,2*nattn)
                               end if
                               ilvec(:,nattn) = p
                               iatt(nattn) = i
                            end if
                         end if
                      end do
                   end do
                end do
             end do
          end if
          call realloc(ilvec,3,nattn)
          call realloc(iatt,nattn)
          write (uout,'(99(A,X))') "  Attractors after remapping =", string(nattn)

          ! allocate the sij
          if (allocated(res(l)%sijc)) deallocate(res(l)%sijc)
          allocate(res(l)%sijc(nmo,nmo,bas%nattr,nspin))
          res(l)%sijc = 0d0

          ! write out some info
          write (uout,'(99(A,X))') "  Number of bands (nbnd) =", string(nbnd)
          write (uout,'(99(A,X))') "  ... lattice translations (nlat) =", (string(nwan(j)),j=1,3)
          write (uout,'(99(A,X))') "  ... Wannier functions (nbnd x nlat) =", string(nlat)
          write (uout,'(99(A,X))') "  ... spin channels =", string(nspin)
          if (sy%propi(l)%wancut > 0d0 .and. sy%propi(l)%useu) then 
             write (uout,'(99(A,X))') "  Discarding overlaps if (spr(w1)+spr(w2)) * cutoff > d(cen(w1),cen(w2)), cutoff = ", string(sy%propi(l)%wancut,'f',5,2)
          else
             write (uout,'(99(A,X))') "  Discarding no overlaps."
          end if

          ! prepare the transformed files
          luevc = -1
          luevc_ibnd = 0
          write (uout,'(99(A,X))') "  Writing temporary evc files..."
          call sy%f(fid)%grid%rotate_qe_evc(luevc,luevc_ibnd,sy%propi(l)%useu)

          ! calculate overlaps
          write (uout,'(99(A,X))') "# Calculating overlaps..."
          call calc_sij_wannier(fid,sy%propi(l)%wancut,sy%propi(l)%useu,bas%imtype,nattn,iatt,ilvec,&
             idg1,bas%xattr,dat,luevc,luevc_ibnd,res(l)%sijc)
          deallocate(iatt,ilvec)
          if (allocated(idg1)) deallocate(idg1)

          ! close the rotated evc scratch files
          if (luevc(1) >= 0) call fclose(luevc(1))
          if (luevc(2) >= 0) call fclose(luevc(2))

          ! write the checkpoint
          if (sy%propi(l)%sijchk) then
             write (uout,'("# Writing Sij checkpoint file: ",A)') trim(sijfname)
             call write_sijchk(sijfname,nbnd,nbndw,nwan,nmo,nlat,nspin,bas%nattr,res(l)%sijc)
          end if
       end if ! calcsij

       ! write (*,*) "checking S sum rules"
       ! do ix1 = 1, nbndw(1)
       !    do ix2 = 1, nbndw(2)
       !       do is = 1, nspin
       !          aa = 0d0
       !          do imo = 1, nmo
       !             call unpackidx(imo,ia,ja,ka,iba,nmo,nbnd,nwan)
       !             if (iba /= ix1) cycle
       !             do jmo = 1, nmo
       !                call unpackidx(jmo,ib,jb,kb,ibb,nmo,nbnd,nwan)
       !                if (ibb /= ix2) cycle
       !                aa = aa + sum(res(l)%sijc(jmo,imo,:,is))
       !             end do
       !          end do
       !          write (*,*) is, ix1, ix2, aa
       !       end do
       !    end do
       ! end do
       ! stop 1

       !!! calculate Fa !!!
       write (uout,'("# Calculating Fa")')

       ! calculate the index mapping in order to build the fa matrix
       ! kmo = imap(imo,jlat) gives the Wannier function index kmo
       ! resulting from taking the Wannier function imo and
       ! translating by lattice vector jlat
       allocate(imap(nmo,nlat))
       do imo = 1, nmo
          call unpackidx(imo,ia,ja,ka,iba,nmo,nbnd,nwan)
          k = 0
          do ic = 0, nwan(1)-1
             do jc = 0, nwan(2)-1
                do kc = 0, nwan(3)-1
                   k = k + 1
                   idx = (/ia-ic, ja-jc, ka-kc/)
                   idx = modulo(idx,nwan)
                   call packidx(idx(1),idx(2),idx(3),iba,imap(imo,k),nmo,nbnd,nwan)
                end do
             end do
          end do
       end do

       if (allocated(res(l)%fa)) deallocate(res(l)%fa)
       allocate(res(l)%fa(bas%nattr,bas%nattr,nlat,nspin))
       res(l)%fa = 0d0
       !$omp parallel do private(fatemp,ia,ja,ka,iba,ib,jb,kb,ibb) schedule(dynamic)
       do i = 1, bas%nattr
          do j = 1, bas%nattr
             do is = 1, nspin
                do k = 1, nlat
                   fatemp = 0d0
                   do imo = 1, nmo
                      call unpackidx(imo,ia,ja,ka,iba,nmo,nbnd,nwan)
                      ! if (iba > nbndw(is)) cycle
                      do jmo = 1, nmo
                         call unpackidx(jmo,ib,jb,kb,ibb,nmo,nbnd,nwan)
                         ! if (ibb > nbndw(is)) cycle
                         fatemp = fatemp + real(res(l)%sijc(jmo,imo,i,is) * res(l)%sijc(imap(imo,k),imap(jmo,k),j,is),8)
                      end do
                   end do
                   !$omp critical (addfa)
                   res(l)%fa(i,j,k,is) = fatemp
                   !$omp end critical (addfa)
                end do
             end do
          end do
       end do
       !$omp end parallel do
       deallocate(imap)

       ! write (*,*) "Check Fa...", sum(res(l)%fa(:,:,:,:))
       ! write (*,*) "Atomic charges..."
       ! do i = 1, bas%nattr
       !    write (*,*) i, sum(res(l)%fa(i,:,:,:)), sum(res(l)%fa(:,i,:,:))
       ! end do
       ! write (*,*) "Spin charges..."
       ! do is = 1, nspin
       !    do i = 1, bas%nattr
       !       write (*,*) i, sum(res(l)%fa(i,:,:,is)), sum(res(l)%fa(:,i,:,is))
       !    end do
       ! end do
       ! stop 1
       
       ! write the checkpoint file
       if (sy%propi(l)%fachk) then
          write (uout,'("# Writing Fa checkpoint file: ",A)') trim(fafname)
          call write_fachk(fafname,nbnd,nbndw,nwan,nmo,nlat,nspin,bas%nattr,res(l)%fa)
       end if

       ! finished successfully
999    continue
       if (allocated(res(l)%sijc)) deallocate(res(l)%sijc)
       res(l)%done = .true.
       res(l)%reason = ""
       res(l)%outmode = out_delocwan
       res(l)%nwan = nwan
       res(l)%nspin = nspin
   end do ! l = 1, sy%npropi

    ! clean up
    if (bas%imtype == imtype_yt) then
       if (allocated(w)) deallocate(w)
       call ytdata_clean(dat)
    end if

  end subroutine intgrid_deloc_wannier

  !> Write the Sij checkpoint file (Wannier DI integration).
  subroutine write_sijchk(sijfname,nbnd,nbndw,nwan,nmo,nlat,nspin,nattr,sij)
    use tools_io, only: fopen_write, fclose
    character(len=*), intent(in) :: sijfname
    integer, intent(in) :: nbnd, nbndw(2), nwan(3), nmo, nlat, nspin, nattr
    complex*16, intent(in) :: sij(:,:,:,:)

    integer :: lu

    lu = fopen_write(sijfname,"unformatted")
    write (lu) nbnd, nbndw, nwan, nmo, nlat, nspin, nattr
    write (lu) sij
    call fclose(lu)
    
  end subroutine write_sijchk

  !> Write the Fa checkpoint file (Wannier DI integration).
  subroutine write_fachk(fafname,nbnd,nbndw,nwan,nmo,nlat,nspin,nattr,fa)
    use tools_io, only: fopen_write, fclose
    character(len=*), intent(in) :: fafname
    integer, intent(in) :: nbnd, nbndw(2), nwan(3), nmo, nlat, nspin, nattr
    real*8, intent(in) :: fa(:,:,:,:)

    integer :: lu

    lu = fopen_write(fafname,"unformatted")
    write (lu) nbnd, nbndw, nwan, nmo, nlat, nspin, nattr
    write (lu) fa
    call fclose(lu)
    
  end subroutine write_fachk

  !> Read the header for the Sij/Fa checkpoint file (Wannier DI
  !> integration). If found and read, return .true.
  function read_chk_header(fname,nbnd,nbndw,nwan,nmo,nlat,nspin,nattr) result(haschk)
    use tools_io, only: fopen_read, fclose
    character(len=*), intent(in) :: fname
    integer, intent(out) :: nbnd, nbndw(2), nwan(3), nmo, nlat, nspin, nattr
    logical :: haschk

    integer :: lu

    inquire(file=fname,exist=haschk)
    if (.not.haschk) return
    lu = fopen_read(fname,"unformatted")
    read (lu) nbnd, nbndw, nwan, nmo, nlat, nspin, nattr
    call fclose(lu)

  end function read_chk_header

  !> Read the body of the Sij checkpoint file (Wannier DI integration).
  subroutine read_sijchk_body(sijfname,sij)
    use tools_io, only: fopen_read, fclose
    character(len=*), intent(in) :: sijfname
    complex*16, intent(inout) :: sij(:,:,:,:)

    integer :: lu

    lu = fopen_read(sijfname,"unformatted")
    read (lu)
    read (lu) sij
    call fclose(lu)

  end subroutine read_sijchk_body

  !> Read the body of the Fa checkpoint file (Wannier DI integration).
  subroutine read_fachk_body(fafname,fa)
    use tools_io, only: fopen_read, fclose
    character(len=*), intent(in) :: fafname
    real*8, intent(inout) :: fa(:,:,:,:)

    integer :: lu

    lu = fopen_read(fafname,"unformatted")
    read (lu)
    read (lu) fa
    call fclose(lu)

  end subroutine read_fachk_body

  !> Calculate the atomic overlap matrices (sij) from the complex
  !> Wannier functions in field fid. Use integration method imtype
  !> (bader/yt), with natt1 remapped attractors, iatt = attractor
  !> mapping, ilvec = attractor lattice vector, idg1 = grid assignment
  !> to attractors in Bader, xattr = attractor position, dat = YT data
  !> type. luevc are the two scratch files for the rotated evc and
  !> luevc_ibnd are the band pointers in those files.
  subroutine calc_sij_wannier(fid,wancut,useu,imtype,natt1,iatt,ilvec,idg1,xattr,dat,luevc,luevc_ibnd,sij)
    use systemmod, only: sy
    use yt, only: yt_weights, ytdata, ytdata_clean
    use crystalmod, only: crystal
    use crystalseedmod, only: crystalseed
    use tools_io, only: ferror, faterr, uout, string
    integer, intent(in) :: fid
    real*8, intent(in) :: wancut
    logical, intent(in) :: useu
    integer, intent(in) :: imtype
    integer, intent(in) :: natt1
    integer, intent(in) :: iatt(natt1)
    integer, intent(in) :: ilvec(3,natt1)
    integer, intent(in) :: idg1(:,:,:)
    real*8, intent(in) :: xattr(:,:)
    integer, intent(in) :: luevc(2)
    type(ytdata), intent(in) :: dat
    integer, intent(inout) :: luevc_ibnd(2)
    complex*16, intent(out) :: sij(:,:,:,:)

    integer :: i, is, ibnd1, ibnd2
    integer :: imo, imo1, ia, ja, ka, iba, ilata, jmo, jmo1, ib, jb, kb, ibb, ilatb
    integer :: n(3), nbnd, nbndw(2), nwan(3), nlat, nmo, nspin
    integer :: ncalc, m1, m2, m3, p(3)
    real*8 :: d0, d2, x(3), xs(3)
    type(crystalseed) :: ncseed
    type(crystal) :: nc
    logical, allocatable :: lovrlp(:,:,:,:,:,:)
    complex*16, allocatable :: psic(:,:,:), psic2(:,:,:)
    complex*16 :: padd
    complex*16, allocatable :: f1(:,:,:,:), f2(:,:,:,:)
    real*8, allocatable :: w(:,:,:)
    logical, allocatable :: wmask(:,:,:)

    sij = 0d0
    n = sy%f(sy%iref)%grid%n
    nwan = sy%f(fid)%grid%qe%nk
    nlat = sy%f(fid)%grid%qe%nks
    nspin = sy%f(fid)%grid%qe%nspin
    nbnd = sy%f(fid)%grid%qe%nbnd
    nbndw = sy%f(fid)%grid%qe%nbndw
    nmo = nlat * nbnd

    ! build the supercell
    ncseed%isused = .true.
    do i = 1, 3
       ncseed%m_x2c(:,i) = sy%c%m_x2c(:,i) * nwan(i)
    end do
    ncseed%useabr = 2
    ncseed%nat = 0
    ncseed%havesym = 0
    ncseed%findsym = 0
    ncseed%ismolecule = sy%c%ismolecule
    call nc%struct_new(ncseed,.true.)

    if (any(n /= sy%f(fid)%grid%n)) &
       call ferror("calc_sij_wannier","inconsistent grid sizes",faterr)
    allocate(psic(n(1),n(2),n(3)))
    allocate(f1(n(1),n(2),n(3),nlat))
    allocate(f2(n(1),n(2),n(3),nlat))
    allocate(lovrlp(0:nwan(1)-1,0:nwan(2)-1,0:nwan(3)-1,0:nwan(1)-1,0:nwan(2)-1,0:nwan(3)-1))
    
    ! the big loop
    if (imtype == imtype_yt) &
       allocate(w(n(1),n(2),n(3)),wmask(n(1),n(2),n(3)),psic2(n(1),n(2),n(3)))
    do is = 1, nspin
       do ibnd1 = 1, nbndw(is)
          ! first wannier function
          call sy%f(fid)%grid%get_qe_wnr(ibnd1,is,luevc,luevc_ibnd,f1)

          do ibnd2 = ibnd1, nbndw(is)
             ! second wannier function
             if (ibnd1 == ibnd2) then
                f2 = f1
             else
                call sy%f(fid)%grid%get_qe_wnr(ibnd2,is,luevc,luevc_ibnd,f2)
             endif

             ! lovrlp
             lovrlp = .true.
             if (wancut > 0d0 .and. useu) then
                d0 = (sy%f(fid)%grid%qe%spread(ibnd1,is)+sy%f(fid)%grid%qe%spread(ibnd2,is)) * wancut
                do imo = 1, nmo
                   call unpackidx(imo,ia,ja,ka,iba,nmo,nbnd,nwan)
                   if (iba /= ibnd1) cycle
                   do jmo = 1, nmo
                      call unpackidx(jmo,ib,jb,kb,ibb,nmo,nbnd,nwan)
                      if (ibb /= ibnd2) cycle
                      x = (sy%f(fid)%grid%qe%center(:,ibnd1,is) + (/ia,ja,ka/) - (sy%f(fid)%grid%qe%center(:,ibnd2,is) + (/ib,jb,kb/))) / real(nwan,8)
                      call nc%shortest(x,d2)
                      if (d2 > d0) &
                         lovrlp(ia,ja,ka,ib,jb,kb) = .false.
                   end do
                end do
             end if

             ncalc = 0
             if (imtype == imtype_bader) then
                ! bader integration
                psic = 0d0
                !$omp parallel do private(ia,ja,ka,iba,ib,jb,kb,ibb,padd,imo1,jmo1,ilata,ilatb) firstprivate(psic) schedule(dynamic)
                do imo = 1, nmo
                   call unpackidx(imo,ia,ja,ka,iba,nmo,nbnd,nwan)
                   if (iba /= ibnd1) cycle
                   ilata = 1 + ka + nwan(3) * (ja + nwan(2) * ia)
                   do jmo = 1, nmo
                      call unpackidx(jmo,ib,jb,kb,ibb,nmo,nbnd,nwan)
                      if (ibb /= ibnd2) cycle
                      if (.not.lovrlp(ia,ja,ka,ib,jb,kb)) cycle
                      ilatb = 1 + kb + nwan(3) * (jb + nwan(2) * ib)

                      psic = conjg(f1(:,:,:,ilata)) * f2(:,:,:,ilatb)
                      do i = 1, natt1
                         padd = sum(psic,idg1==i)
                         call packidx(ia-ilvec(1,i),ja-ilvec(2,i),ka-ilvec(3,i),iba,imo1,nmo,nbnd,nwan)
                         call packidx(ib-ilvec(1,i),jb-ilvec(2,i),kb-ilvec(3,i),ibb,jmo1,nmo,nbnd,nwan)
                         !$omp critical (add)
                         ncalc = ncalc + 1
                         sij(imo1,jmo1,iatt(i),is) = sij(imo1,jmo1,iatt(i),is) + padd
                         if (ibnd1 /= ibnd2) then
                            sij(jmo1,imo1,iatt(i),is) = sij(jmo1,imo1,iatt(i),is) + conjg(padd)
                         end if
                         !$omp end critical (add)
                      end do ! natt1
                   end do ! jmo
                end do ! imo
                !$omp end parallel do
             else
                ! yt integration
                psic = 0d0
                psic2 = 0d0
                w = 0d0
                wmask = .false.
                !$omp parallel do private(p,x,xs,d2,ia,ja,ka,iba,ib,jb,kb,ibb,padd,imo1,jmo1,ilata,ilatb) firstprivate(psic,psic2,w,wmask) schedule(dynamic)
                do i = 1, natt1
                   call yt_weights(din=dat,idb=iatt(i),w=w)
                   wmask = .false.
                   do m3 = 1, n(3)
                      do m2 = 1, n(2)
                         do m1 = 1, n(1)
                            if (abs(w(m1,m2,m3)) < 1d-15) cycle
                            p = (/m1,m2,m3/)
                            x = real(p-1,8) / n - xattr(:,iatt(i))
                            xs = x
                            call sy%c%shortest(xs,d2)
                            p = nint(x - sy%c%c2x(xs))
                            wmask(m1,m2,m3) = all(p == ilvec(:,i))
                         end do
                      end do
                   end do

                   psic2 = 0d0
                   do imo = 1, nmo
                      call unpackidx(imo,ia,ja,ka,iba,nmo,nbnd,nwan)
                      if (iba /= ibnd1) cycle
                      ilata = 1 + ka + nwan(3) * (ja + nwan(2) * ia)
                      where (wmask)
                         psic2 = conjg(f1(:,:,:,ilata)) * w
                      end where

                      do jmo = 1, nmo
                         call unpackidx(jmo,ib,jb,kb,ibb,nmo,nbnd,nwan)
                         if (ibb /= ibnd2) cycle
                         if (.not.lovrlp(ia,ja,ka,ib,jb,kb)) cycle
                         ilatb = 1 + kb + nwan(3) * (jb + nwan(2) * ib)
                         where (wmask)
                            psic =  psic2 * f2(:,:,:,ilatb)
                         end where

                         padd = sum(psic,wmask)
                         call packidx(ia-ilvec(1,i),ja-ilvec(2,i),ka-ilvec(3,i),iba,imo1,nmo,nbnd,nwan)
                         call packidx(ib-ilvec(1,i),jb-ilvec(2,i),kb-ilvec(3,i),ibb,jmo1,nmo,nbnd,nwan)
                         !$omp critical (add)
                         ncalc = ncalc + 1
                         sij(imo1,jmo1,iatt(i),is) = sij(imo1,jmo1,iatt(i),is) + padd
                         if (ibnd1 /= ibnd2) then
                            sij(jmo1,imo1,iatt(i),is) = sij(jmo1,imo1,iatt(i),is) + conjg(padd)
                         end if
                         !$omp end critical (add)
                      end do ! jmo
                   end do ! imo
                end do ! i = 1, natt1
                !$omp end parallel do
             end if ! imtype == bader/yt

             write (uout,'(4X,"Bands (",A,",",A,") of total ",A,". Spin ",A,"/",A,". Overlaps: ",A,"/",A)') &
                string(ibnd1), string(ibnd2), string(nbndw(is)), string(is), string(nspin),&
                string(ncalc), string(natt1*nlat*nlat)
          end do ! ibnd2
       end do ! ibnd1 
    end do ! is

    ! clean up
    deallocate(f1,f2,psic,lovrlp)
    if (imtype == imtype_yt) &
       deallocate(w,wmask,psic2)

    ! scale (the omega comes from wannier)
    sij = sij / (n(1)*n(2)*n(3))

  end subroutine calc_sij_wannier

  !> Dummy function for quadpack integration
  function quadpack_f(x,unit,xnuc) result(res)
    use systemmod, only: sy

    real*8, intent(in) :: x
    real*8, intent(in) :: unit(3)
    real*8, intent(in) :: xnuc(3)
    real*8 :: res(sy%npropi)

    real*8 :: xaux(3)

    xaux = xnuc + x * unit
    call sy%grdall(xaux,res)
    res = res * x * x

  end function quadpack_f

  !> Write calculated multipole moments to the output. bas =
  !> integration driver data, res(1:npropi) = results.
  subroutine int_output_multipoles(bas,res)
    use systemmod, only: sy
    use tools_io, only: uout, string, ioj_left, ioj_center
    use types, only: basindat, int_result, out_mpoles
    type(basindat), intent(in) :: bas
    type(int_result), intent(in) :: res(:)
    
    integer :: i, j, k, l, nn, fid, lmax
    ! integer :: i, j, k, nn, n, l, lmax, fid
    integer, allocatable :: l_(:), m_(:)
    character(len=:), allocatable :: lbl
    character*3 :: ls, ms
    character(len=:), allocatable :: sncp, scp, sname, sz, smult
    
    do l = 1, sy%npropi
       if (.not.res(l)%done .or. res(l)%outmode /= out_mpoles) cycle
       fid = sy%propi(l)%fid
       write (uout,'("* Basin multipole moments (using real solid harmonics)")')
       write (uout,'("+ Integrated property (number ",A,"): ",A)') string(l), string(sy%propi(l)%prop_name)
       write (uout,'("+ The calculated multipoles are: ")')
       write (uout,'("    Q_lm^A = int_A rho(r) * Rlm(r) dr ")')
       write (uout,'("  where the integral is over the basin of A, and Rlm is a real solid harmonic.")')
       write (uout,'("  The coordinates are referred to the attractor of the A basin. All quantities")')
       write (uout,'("  in atomic units.")')
       write (uout,*)

       ! figure out the indices for the labels
       lmax = sy%propi(l)%lmax
       allocate(l_((lmax+1)*(lmax+1)),m_((lmax+1)*(lmax+1)))
       nn = 0
       do i = 0, lmax
          do j = -i, i
             nn = nn + 1
             l_(nn) = i
             m_(nn) = j
          end do
       end do
       
       ! pretty output
       nn = (lmax+1)**2/5
       if (mod((lmax+1)**2,5) /= 0) nn = nn + 1
       do i = 1, nn
          ! header
          lbl = "# Id   cp   ncp   Name  Z   "
          do j = (i-1)*5+1,min(5*i,(lmax+1)**2)
             if (j == 1) then
                lbl = lbl // " " // string("1",15,justify=ioj_center)
             elseif (j == 2) then
                lbl = lbl // " " // string("x",15,justify=ioj_center)
             elseif (j == 3) then
                lbl = lbl // " " // string("z",15,justify=ioj_center)
             elseif (j == 4) then
                lbl = lbl // " " // string("y",15,justify=ioj_center)
             elseif (j == 5) then
                lbl = lbl // " " // string("sq(3)/2(x^2-y^2)",15,justify=ioj_center)
             elseif (j == 6) then
                lbl = lbl // " " // string("sq(3)xz",15,justify=ioj_center)
             elseif (j == 7) then
                lbl = lbl // " " // string("(3z^2-r^2)/2",15,justify=ioj_center)
             elseif (j == 8) then
                lbl = lbl // " " // string("sq(3)yz",15,justify=ioj_center)
             elseif (j == 9) then
                lbl = lbl // " " // string("sq(3)xy",15,justify=ioj_center)
             else
                write (ls,'(I3)') l_(j)
                write (ms,'(I3)') abs(m_(j))
                if (m_(j) <= 0) then
                   lbl = lbl // " " // string("C("//string(ls)//","//string(ms)//")",15,justify=ioj_center)
                else
                   lbl = lbl // " " // string("S("//string(ls)//","//string(ms)//")",15,justify=ioj_center)
                end if
             endif
          end do
          write (uout,'(A)') lbl

          ! body
          do j = 1, bas%nattr
             call assign_strings(j,bas%icp(j),.false.,scp,sncp,sname,smult,sz)
             write (uout,'(2X,99(A,X))') &
                string(j,4,ioj_left), scp, sncp, sname, sz, &
                (string(res(l)%mpole((i-1)*5+1+k,j),'e',15,8,4),k=0,min(4,size(res(l)%mpole,1)-(i-1)*5-1))
          enddo
          if (i < nn) then
             write (uout,*)
          else
             write (uout,'(32("-"),99(A))') ("----------------",j=1,5)
          end if
       end do
       deallocate(l_,m_)
       write (uout,*)
    end do

  end subroutine int_output_multipoles

  !> Output the delocalization indices, Wannier.  bas = integration
  !> driver data, res(1:npropi) = results.
  subroutine int_output_deloc_wannier(bas,res)
    use crystalmod, only: crystal
    use crystalseedmod, only: crystalseed
    use global, only: iunit, iunitname0, dunit0
    use tools, only: qcksort
    use tools_io, only: uout, string, ioj_left, ioj_right, fopen_read,&
       fopen_write, fclose
    use types, only: basindat, int_result, out_delocwan
    type(basindat), intent(in) :: bas
    type(int_result), intent(in) :: res(:)

    integer :: i, j, k, l, m
    integer :: fid, natt, nwan(3), nspin, nlat, natt
    real*8 :: fspin, xli, xnn, r1(3), asum, d2, raux
    real*8, allocatable :: dimol(:,:,:,:,:), limol(:), namol(:)
    real*8, allocatable :: dist(:), diout(:), xcm(:,:)
    integer, allocatable :: io(:), ilvec(:,:), idat(:), idxmol(:,:)
    integer :: ia, ja
    integer :: ic, jc, kc, lvec1(3), lvec2(3), lvec3(3)
    character(len=:), allocatable :: sncp, scp, sname, sz, smult
    type(crystal) :: cr1
    type(crystalseed) :: ncseed

    do l = 1, sy%npropi
       if (.not.res(l)%done) cycle
       if (res(l)%outmode /= out_delocwan) cycle

       write (uout,'("* Localization and delocalization indices")')

       ! header
       fid = sy%propi(l)%fid
       write (uout,'("+ Integrated property (number ",A,"): ",A)') string(l), string(sy%propi(l)%prop_name)

       ! some integers for the run
       nwan = res(l)%nwan
       nspin = res(l)%nspin
       nlat = nwan(1)*nwan(2)*nwan(3)
       natt = bas%nattr

       ! spin factor
       if (nspin == 1) then
          fspin = 2d0
       else
          fspin = 1d0
       end if
       
       ! localization indices
       write (uout,'("+ Localization indices")')
       write (uout,'("# Id   cp   ncp   Name  Z       LI(A)           N(A)")')
       do i = 1, natt
          call assign_strings(i,bas%icp(i),.false.,scp,sncp,sname,smult,sz)
          xli = sum(abs(res(l)%fa(i,i,1,:))) * fspin
          xnn = sum(abs(res(l)%fa(i,:,:,:))) * fspin
          write (uout,'(2X,99(A,X))') string(i,4,ioj_left), scp, sncp, sname, sz, &
             string(xli,'f',15,8,4), string(xnn,'f',12,8,4)
       end do
       write (uout,*)

       ! build the supercell
       ncseed%isused = .true.
       do i = 1, 3
          ncseed%m_x2c(:,i) = sy%c%m_x2c(:,i) * nwan(i)
       end do
       ncseed%useabr = 2
       ncseed%nat = 0
       ncseed%havesym = 0
       ncseed%findsym = 0
       ncseed%ismolecule = sy%c%ismolecule
       call cr1%struct_new(ncseed,.true.)

       write (uout,'("+ Delocalization indices")')
       write (uout,'("  Each block gives information about a single atom in the main cell.")')
       write (uout,'("  First line: localization index. Next lines: delocaliazation index")')
       write (uout,'("  with all atoms in the environment. Last line: sum of LI + 0.5 * DIs,")')
       write (uout,'("  equal to the atomic population. Distances are in ",A,".")') iunitname0(iunit)
       allocate(dist(natt*nlat),io(natt*nlat),diout(natt*nlat),ilvec(3,natt*nlat),idat(natt*nlat))
       do i = 1, natt
          call assign_strings(i,bas%icp(i),.false.,scp,sncp,sname,smult,sz)
          write (uout,'("# Attractor ",A," (cp=",A,", ncp=",A,", name=",A,", Z=",A,") at: ",3(A,2X))') & 
             string(i), trim(scp), trim(sncp), trim(adjustl(sname)), trim(sz), (trim(string(bas%xattr(j,i),'f',12,7)),j=1,3)
          write (uout,'("# Id   cp   ncp   Name  Z    Latt. vec.     ----  Cryst. coordinates ----       Distance        LI/DI")')

          ! precompute the localization/delocalization indices for this atom and
          ! location and distance information
          dist = 0d0
          k = 0
          m = 0
          do ic = 0, nwan(1)-1
             do jc = 0, nwan(2)-1
                do kc = 0, nwan(3)-1
                   k = k + 1
                   do j = 1, natt
                      m = m + 1
                      io(m) = m
                      r1 = (bas%xattr(:,j) + (/ic,jc,kc/) - bas%xattr(:,i)) / real(nwan,8)
                      call cr1%shortest(r1,d2)
                      dist(m) = d2 * dunit0(iunit)
                      diout(m) = 2d0 * sum(abs(res(l)%fa(i,j,k,:))) * fspin
                      if (dist(m) < 1d-5) diout(m) = diout(m) / 2d0
                      idat(m) = j
                      ilvec(:,m) = nint(bas%xattr(:,i) + cr1%c2x(r1) * nwan - bas%xattr(:,j))
                   end do
                end do
             end do
          end do

          ! sort by increasing distance and output for this atom
          call qcksort(dist,io,1,natt*nlat)
          asum = 0d0
          do m = 1, natt*nlat
             j = io(m)
             if (dist(j) < 1d-5) then
                write (uout,'(2X,"Localization index",71("."),A)') string(diout(j),'f',12,8,4)
                asum = asum + diout(j)
             else
                call assign_strings(j,bas%icp(idat(j)),.false.,scp,sncp,sname,smult,sz)
                r1 = bas%xattr(:,idat(j)) + ilvec(:,j)
                write (uout,'(2X,99(A,X))') string(j,4,ioj_left), scp, sncp, sname, sz,&
                   (string(ilvec(k,j),3,ioj_right),k=1,3), (string(r1(k),'f',12,7,4),k=1,3),&
                   string(dist(j),'f',12,7,4), string(diout(j),'f',12,8,4)
                asum = asum + 0.5d0 * diout(j)
             end if
          end do
          write (uout,'(2X,"Total (atomic population)",64("."),A)') string(asum,'f',12,8,4)
          write (uout,*)
       end do

       ! Integrated molecular LI/DI
       if (.not.sy%c%ismolecule .and. all(sy%c%mol(1:sy%c%nmol)%discrete)) then
          allocate(idxmol(2,natt))
          ! Assign attractors to molecules
          idxmol = 0
          do i = 1, natt
             jlo: do j = 1, sy%c%nmol
                do k = 1, sy%c%mol(j)%nat
                   if (bas%icp(i) == sy%c%mol(j)%at(k)%cidx) then
                      idxmol(1,i) = j
                      idxmol(2,i) = k
                      exit jlo
                   end if
                end do
             end do jlo
          end do
          
          ! assign DIs to molecules
          allocate(dimol(sy%c%nmol,sy%c%nmol,0:nwan(1)-1,0:nwan(2)-1,0:nwan(3)-1),limol(sy%c%nmol),namol(sy%c%nmol))
          dimol = 0d0
          limol = 0d0
          namol = 0d0
          do i = 1, natt
             ia = idxmol(1,i)
             if (ia == 0) cycle
             limol(ia) = limol(ia) + sum(abs(res(l)%fa(i,i,1,:))) * fspin
             namol(ia) = namol(ia) + sum(abs(res(l)%fa(i,:,:,:))) * fspin
             lvec1 = sy%c%mol(ia)%at(idxmol(2,i))%lvec
             k = 0
             m = 0
             do ic = 0, nwan(1)-1
                do jc = 0, nwan(2)-1
                   do kc = 0, nwan(3)-1
                      k = k + 1
                      do j = 1, natt
                         m = m + 1
                         if (idxmol(1,j) == 0) cycle
                         if (i == j .and. k == 1) cycle
                         ja = idxmol(1,j)
                         if (ja == 0) cycle
                         lvec2 = sy%c%mol(ja)%at(idxmol(2,j))%lvec
                         lvec3 = lvec1 - lvec2 + (/ic,jc,kc/)
                         lvec3 = modulo(lvec3,nwan)
                         raux = 2d0 * sum(abs(res(l)%fa(i,j,k,:))) * fspin
                         if (ia == ja .and. all(lvec3 == 0)) then
                            limol(ia) = limol(ia) + 0.5d0 * raux
                         else
                            dimol(ia,ja,lvec3(1),lvec3(2),lvec3(3)) = &
                               dimol(ia,ja,lvec3(1),lvec3(2),lvec3(3)) + raux
                         endif
                      end do
                   end do
                end do
             end do
          end do

          ! localization indices
          write (uout,'("* Integrated molecular properties")')
          write (uout,'("+ Localization indices")')
          write (uout,'("# Mol       LI(A)           N(A)")')
          do i = 1, sy%c%nmol
             write (uout,'(2X,99(A,X))') & 
                string(i,4,ioj_left), string(limol(i),'f',15,8,4), string(namol(i),'f',12,8,4)
          end do
          write (uout,*)
          
          ! centers of mass
          allocate(xcm(3,sy%c%nmol))
          do i = 1, sy%c%nmol
             xcm(:,i) = sy%c%mol(i)%cmass()
             xcm(:,i) = sy%c%c2x(xcm(:,i))
          end do

          write (uout,'("+ Delocalization indices")')
          do i = 1, sy%c%nmol
             ! name the molecule
             write (uout,'("# Molecule ",A," with ",A," atoms at ",3(A,X))') string(i), string(sy%c%mol(i)%nat),&
                (string(xcm(j,i),'f',10,6,3),j=1,3)
             write (uout,'("# Mol   Latt. vec.    ---- Center of mass (cryst) ----      Distance      LI/DI")')

             m = 0 
             do ic = 0, nwan(1)-1
                do jc = 0, nwan(2)-1
                   do kc = 0, nwan(3)-1
                      do j = 1, sy%c%nmol
                         m = m + 1
                         io(m) = m
                         r1 = (xcm(:,j) + (/ic,jc,kc/) - xcm(:,i)) / real(nwan,8)
                         call cr1%shortest(r1,d2)
                         dist(m) = d2 * dunit0(iunit)
                         diout(m) = dimol(i,j,ic,jc,kc)
                         idat(m) = j
                         ilvec(:,m) = nint(xcm(:,i) + cr1%c2x(r1) * nwan - xcm(:,j))
                      end do
                   end do
                end do
             end do

             ! sort by increasing distance and output for this molecule
             call qcksort(dist,io,1,sy%c%nmol*nlat)
             asum = 0d0
             do m = 1, sy%c%nmol*nlat
                j = io(m)
                if (dist(j) < 1d-5) then
                   write (uout,'(2X,"Localization index",51("."),A)') string(limol(i),'f',12,8,4)
                   asum = asum + limol(i)
                else
                   r1 = xcm(:,idat(j)) + ilvec(:,j)
                   write (uout,'(2X,99(A,X))') string(idat(j),4,ioj_left), &
                      (string(ilvec(k,j),3,ioj_right),k=1,3), (string(r1(k),'f',12,7,4),k=1,3),&
                      string(dist(j),'f',12,7,4), string(diout(j),'f',12,8,4)
                   asum = asum + 0.5d0 * diout(j)
                end if
             end do
             write (uout,'(2X,"Total (atomic population)",44("."),A)') string(asum,'f',12,8,4)
             write (uout,*)
          end do
          deallocate(dimol,limol,namol,idxmol,xcm)
       end if
       
       ! clean up
       call cr1%end()
       deallocate(dist,io,diout,ilvec,idat)
    end do

  end subroutine int_output_deloc_wannier

  !> Assign strings for attractor i. icp is the CP identifier for the
  !> attractor. usesym controls whether the multiplicit will be
  !> written to the output. The output strings are scp (the cell CP
  !> identifier, or -- if not a CP attractor), sncp (the
  !> non-equivalent CP identifier, or -- if not a CP attractor), sname
  !> (the name of the CP), smult (CP multiplicity), and sz (atomic
  !> number, if the CP is an atom).
  subroutine assign_strings(i,icp,usesym,scp,sncp,sname,smult,sz)
    use systemmod, only: sy
    use tools_io, only: string, ioj_left, ioj_center
    integer, intent(in) :: i
    integer, intent(in) :: icp
    logical, intent(in) :: usesym
    character(len=:), allocatable, intent(out) :: sncp, scp, sname, sz, smult

    integer :: idx

    if (icp > 0) then
       ! this is a cp
       idx = sy%f(sy%iref)%cpcel(icp)%idx
       scp = string(icp,4,ioj_left)
       sncp = string(idx,4,ioj_left)
       sname = string(sy%f(sy%iref)%cp(idx)%name,6,ioj_center)
       smult = string(sy%f(sy%iref)%cp(idx)%mult,4,ioj_center)
       if (sy%f(sy%iref)%cp(idx)%isnuc) then
          sz = string(sy%c%spc(sy%c%at(idx)%is)%z,2,ioj_left)
       else
          sz = "--"
       endif
    else
       ! this is an unknown nnm
       scp = " -- "
       sncp = " -- "
       sname = "  ??  "
       smult = string(1,4,ioj_center)
       sz = "--"
    end if
    if (.not.usesym) smult = " -- "
    
  end subroutine assign_strings

  !> Plot the atomic basins found by YT or BADER to graphical files.
  !> bas = integration driver data.
  subroutine int_gridbasins(bas)
    use yt, only: yt_weights, ytdata_clean, ytdata
    use systemmod, only: sy
    use crystalmod, only: crystal
    use global, only: fileroot
    use graphics, only: grhandle
    use tools_math, only: m_x2c_from_cellpar, matinv, cross
    use tools_io, only: string, uout, ferror, noerr, string
    use types, only: realloc, basindat
    type(basindat), intent(in) :: bas

    character(len=:), allocatable :: str
    integer :: i, j, i1, i2, i3, iaux, n(3), q(3), p(3)
    real*8 :: d2, x(3), x1(3), x2(3), xd(3)
    type(crystal) :: caux
    real*8, allocatable :: w(:,:,:)
    integer, allocatable :: idg0(:,:,:)
    type(ytdata) :: dat
    type(grhandle) :: gr
    integer :: nvert, nf
    real*8, allocatable :: xvert(:,:), xrho(:)
    integer, allocatable :: iface(:,:)

    interface
       ! The definitions and documentation for these functions are in doqhull.c
       subroutine runqhull_basintriangulate_step1(n,x0,xvert,nf) bind(c)
         use, intrinsic :: iso_c_binding, only: c_int, c_double
         integer(c_int), value :: n
         real(c_double) :: x0(3)
         real(c_double) :: xvert(3,n)
         integer(c_int) :: nf
       end subroutine runqhull_basintriangulate_step1
       subroutine runqhull_basintriangulate_step2(nf,iface) bind(c)
         use, intrinsic :: iso_c_binding, only: c_int, c_double
         integer(c_int), value :: nf
         integer(c_int) :: iface(3,nf)
       end subroutine runqhull_basintriangulate_step2
    end interface

    if (bas%ndrawbasin < 0) return

    ! prepare wigner-seitz tetrahedra
    do i = 1, 3
       n(i) = size(bas%idg,i)
    end do
    caux%isinit = .true.
    caux%aa = sy%c%aa / real(n,8)
    caux%bb = sy%c%bb
    caux%m_x2c = m_x2c_from_cellpar(caux%aa,caux%bb)
    caux%m_c2x = matinv(caux%m_x2c)
    call caux%wigner()

    ! output
    write (uout,'("+ Basins written to ",A,"_basins-*.",A/)') trim(fileroot), bas%basinfmt

    ! write the unit cell
    str = trim(fileroot) // "_basins-cell." // bas%basinfmt
    call sy%c%write_3dmodel(str,bas%basinfmt,(/1,1,1/),.true.,.false.,.true.,&
       .true.,.true.,-1d0,(/0d0,0d0,0d0/),-1d0,(/0d0,0d0,0d0/))

    ! prepare the idg array
    allocate(idg0(n(1),n(2),n(3)))
    if (bas%imtype == imtype_bader) then
       idg0 = bas%idg
    elseif (bas%imtype == imtype_yt) then
       allocate(w(n(1),n(2),n(3)))
       call yt_weights(luw=bas%luw,dout=dat)
       do i = 1, bas%nattr
          call yt_weights(din=dat,idb=i,w=w)
          where(w >= 0.5d0)
             idg0 = i
          end where
       end do
       call ytdata_clean(dat)
       deallocate(w)
    endif

    ! write the basins
    allocate(xvert(3,10),xrho(10))
    do i = 1, bas%nattr
       if (bas%ndrawbasin > 0 .and. bas%ndrawbasin /= i) cycle

       nvert = 0
       !$omp parallel do private(p,q,x,xd,d2) schedule(dynamic)
       do i1 = 1, n(1)
          do i2 = 1, n(2)
             do i3 = 1, n(3)
                if (idg0(i1,i2,i3) /= i) cycle

                ! is this point on the border of the basin?
                p = (/i1,i2,i3/)
                do j = 1, caux%ws_nf
                   q = modulo(p + caux%ws_ineighx(:,j) - 1,n) + 1
                   if (idg0(q(1),q(2),q(3)) /= i) then
                      ! move the point to the WS of the attractor and convert to Cartesian
                      x = real(p-1,8) / n
                      xd = x - bas%xattr(:,i)
                      call sy%c%shortest(xd,d2)
                      x = sy%c%x2c(bas%xattr(:,i)) + xd

                      ! add to the list of basin points
                      !$omp critical (addvertex)
                      nvert = nvert + 1
                      if (nvert > size(xvert,2)) then
                         call realloc(xvert,3,2*nvert)
                         call realloc(xrho,2*nvert)
                      end if
                      xvert(:,nvert) = x
                      xrho(nvert) = bas%f(q(1),q(2),q(3))
                      !$omp end critical (addvertex)
                   end if
                end do
             end do
          end do
       end do
       !$omp end parallel do
       deallocate(idg0)

       if (nvert > 0) then
          ! run qhull
          x = sy%c%x2c(bas%xattr(:,i))
          call runqhull_basintriangulate_step1(nvert,x,xvert,nf)
          allocate(iface(3,nf))
          call runqhull_basintriangulate_step2(nf,iface)

          ! orient the faces
          !$omp parallel do private(x1,x2,iaux) schedule(dynamic)
          do j = 1, nf
             x1 = xvert(:,iface(2,j)) - xvert(:,iface(1,j))
             x2 = xvert(:,iface(3,j)) - xvert(:,iface(1,j))
             x1 = cross(x1,x2)

             x2 = (xvert(:,iface(1,j)) + xvert(:,iface(2,j)) + xvert(:,iface(3,j))) / 3d0 - x
             if (dot_product(x1,x2) < 0d0) then
                iaux = iface(1,j)
                iface(1,j) = iface(2,j)
                iface(2,j) = iaux
             end if
          end do
          !$omp end parallel do

          ! write the triangulation to a file
          str = trim(fileroot) // "_basins-" // string(i) // "." // bas%basinfmt
          call gr%open(bas%basinfmt,str)
          call gr%triangulation(nvert,xvert,nf,iface,xrho)
          call gr%close()
          deallocate(iface)
       else
          call ferror("int_gridbasins","Basin " // string(i) // " has zero volume.",noerr)
       end if
    end do
    deallocate(xvert,xrho)

  end subroutine int_gridbasins

  !> Write cube files with the integration weights.  bas = integration
  !> driver data.
  subroutine int_cubew(bas)
    use systemmod, only: sy
    use yt, only: ytdata, yt_weights, ytdata_clean
    use global, only: fileroot
    use tools_io, only: uout, string
    use types, only: basindat
    type(basindat), intent(in) :: bas

    type(ytdata) :: dat
    real*8, allocatable :: w(:,:,:)
    character(len=:), allocatable :: file
    integer :: i

    if (.not.bas%wcube) return
    allocate(w(bas%n(1),bas%n(2),bas%n(3)))
    if (bas%imtype == imtype_yt) then
       w = 0d0
       call yt_weights(luw=bas%luw,dout=dat)
    end if

    do i = 1, bas%nattr
       if (bas%imtype == imtype_yt) then
          call yt_weights(din=dat,idb=i,w=w)
       else
          w = 0d0
          where (bas%idg == i)
             w = 1d0
          end where
       endif
       file = trim(fileroot) // "_wcube_" // string(i,2,pad0=.true.) // ".cube"
       call sy%c%writegrid_cube(w,file,.false.,.false.)
    end do
    write (uout,'("+ Weights written to ",A,"_wcube_*.cube"/)') trim(fileroot)
    deallocate(w)

    if (bas%imtype == imtype_yt) then
       call ytdata_clean(dat)
    end if

  end subroutine int_cubew

  !> Unpacking routine for use in Wannier delocalization index calculations.
  subroutine unpackidx(idx,io,jo,ko,bo,nmo,nbnd,nwan)
    integer, intent(in) :: idx, nmo, nbnd, nwan(3)
    integer, intent(out) :: io, jo, ko, bo

    integer :: iaux

    ! unpack
    iaux = modulo(idx-1,nmo)
    bo = modulo(iaux,nbnd)
    iaux = (idx-1 - bo) / nbnd
    ko = modulo(iaux,nwan(3))
    iaux = (iaux - ko) / nwan(3)
    jo = modulo(iaux,nwan(2))
    iaux = (iaux - jo) / nwan(2)
    io = modulo(iaux,nwan(1))
    bo = bo + 1

  end subroutine unpackidx

  !> Unpacking routine for use in Wannier delocalization index calculations.
  subroutine packidx(io,jo,ko,bo,idx,nmo,nbnd,nwan)
    integer, intent(in) :: io, jo, ko, bo, nmo, nbnd, nwan(3)
    integer, intent(out) :: idx

    integer :: zio, zjo, zko

    ! transformed indices
    zio = modulo(io,nwan(1))
    zjo = modulo(jo,nwan(2))
    zko = modulo(ko,nwan(3))

    ! translate and pack
    idx = bo + nbnd * (zko + nwan(3) * (zjo + nwan(2) * zio))

  end subroutine packidx

end submodule proc
