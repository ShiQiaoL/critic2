# Critic2 targets and sources
dist_bin_SCRIPTS = 
bin_PROGRAMS = critic2
critic2_SOURCES = critic2.F90 c_interface_module.f90 cfftnd.f90 \
	spglib.f90 spglib@proc.f90 keast.f90 param.F90 \
	doqhull.c quadpack.f90 tricks.f90 \
	abinit_private.f90 abinit_private@proc.f90 autocp.f90 autocp@proc.f90 \
	arithmetic.F90 arithmetic@proc.F90 bader.f90 bader@proc.f90 \
	bisect.f90 bisect@proc.f90 config.f90 config@proc.F90 \
	crystalseedmod.f90 crystalseedmod@proc.f90 crystalmod.f90 crystalmod@proc.f90 \
	dftb_private.f90 dftb_private@proc.f90 elk_private.f90 elk_private@proc.f90 \
	environmod.f90 environmod@proc.f90 \
	fieldmod.f90 fieldmod@proc.f90 fieldseedmod.f90 fieldseedmod@proc.f90 \
	flux.f90 flux@proc.f90 fragmentmod.f90 fragmentmod@proc.f90 \
	global.f90 global@proc.F90 graphics.f90 graphics@proc.f90 \
	grid1mod.f90 grid1mod@proc.f90 grid3mod.f90 grid3mod@proc.f90 \
	hashmod.f90 hashmod@proc.f90 hirshfeld.f90 hirshfeld@proc.f90 \
	integration.f90 integration@proc.f90 meshmod.f90 meshmod@proc.f90 \
	molcalc.f90 molcalc@proc.F90 nci.f90 nci@proc.f90 \
	pi_private.f90 pi_private@proc.f90 qe_private.f90 qe_private@proc.f90 \
        qtree_basic.f90 qtree_basic@proc.f90 \
	qtree.f90 qtree@proc.f90 qtree_gpaths.f90 qtree_gpaths@proc.f90 \
	qtree_tetrawork.f90 qtree_tetrawork@proc.f90 qtree_utils.f90 qtree_utils@proc.f90 \
	rhoplot.f90 rhoplot@proc.f90 stm.f90 stm@proc.f90 \
	struct_drivers.f90 struct_drivers@proc.f90 surface.f90 surface@proc.f90 \
	systemmod.f90 systemmod@proc.f90 tools.f90 tools@proc.f90 \
	tools_io.f90 tools_io@proc.F90 tools_math.f90 tools_math@proc.f90 tools_math@lebedev.f90 \
	types.f90 types@proc.f90 wfn_private.f90 wfn_private@proc.F90 \
	wien_private.f90 wien_private@proc.f90 xdm.f90 xdm@proc.f90 \
	yt.f90 yt@proc.f90

if GUI
  noinst_LIBRARIES=libcritic2.a
  libcritic2_a_SOURCES = gui_interface.f90 c_interface_module.f90 cfftnd.f90 \
	spglib.f90 spglib@proc.f90 keast.f90 param.F90 \
	doqhull.c quadpack.f90 tricks.f90 \
	abinit_private.f90 abinit_private@proc.f90 autocp.f90 autocp@proc.f90 \
	arithmetic.F90 arithmetic@proc.F90 bisect.f90 bisect@proc.f90 \
	bader.f90 bader@proc.f90 config.f90 config@proc.F90 \
	crystalseedmod.f90 crystalseedmod@proc.f90 crystalmod.f90 crystalmod@proc.f90 \
	dftb_private.f90 dftb_private@proc.f90 elk_private.f90 elk_private@proc.f90 \
	environmod.f90 environmod@proc.f90 \
	fieldmod.f90 fieldmod@proc.f90 fieldseedmod.f90 fieldseedmod@proc.f90 \
	flux.f90 flux@proc.f90 fragmentmod.f90 fragmentmod@proc.f90 \
	global.f90 global@proc.F90 graphics.f90 graphics@proc.f90 \
	grid1mod.f90 grid1mod@proc.f90 grid3mod.f90 grid3mod@proc.f90 \
	hashmod.f90 hashmod@proc.f90 hirshfeld.f90 hirshfeld@proc.f90 \
	integration.f90 integration@proc.f90 meshmod.f90 meshmod@proc.f90 \
	molcalc.f90 molcalc@proc.F90 nci.f90 nci@proc.f90 \
	pi_private.f90 pi_private@proc.f90 qtree_basic.f90 qtree_basic@proc.f90 \
	qtree.f90 qtree@proc.f90 qtree_gpaths.f90 qtree_gpaths@proc.f90 \
	qtree_tetrawork.f90 qtree_tetrawork@proc.f90 qtree_utils.f90 qtree_utils@proc.f90 \
	rhoplot.f90 rhoplot@proc.f90 stm.f90 stm@proc.f90 \
	struct_drivers.f90 struct_drivers@proc.f90 surface.f90 surface@proc.f90 \
	systemmod.f90 systemmod@proc.f90 tools.f90 tools@proc.f90 \
	tools_io.f90 tools_io@proc.F90 tools_math.f90 tools_math@proc.f90 tools_math@lebedev.f90 \
	types.f90 types@proc.f90 wfn_private.f90 wfn_private@proc.F90 \
	wien_private.f90 wien_private@proc.f90 xdm.f90 xdm@proc.f90 \
	yt.f90 yt@proc.f90

endif

# Library subdirectories
SUBDIRS = oldlibs ciftbx cubpack qhull spglib

# Static libraries
critic2_LDADD=$(top_builddir)/src/oldlibs/libmisc.a $(top_builddir)/src/ciftbx/libciftbx.a \
	$(top_builddir)/src/cubpack/libcubpack.a $(top_builddir)/src/spglib/libspglib.a \
	$(top_builddir)/src/qhull/libqhull_critic.a
critic2_DEPENDENCIES=$(critic2_LDADD)

# Include the subdirectories with the modules
AM_FCFLAGS= -I$(top_builddir)/src/cubpack
AM_CFLAGS= -I$(top_srcdir)/src/qhull

# Data directory
if !WIN
  AM_FCFLAGS+=-DDATADIR='"$(datadir)"'
else
  AM_FCFLAGS+=-DWIN
endif

# Compilation flags (in config.F90)
if !WIN
  DATE2 := $(shell date || echo "(config) @DATE@")
  AM_FCFLAGS+=-DDATE='"$(DATE2)"'
  COMMIT := $(shell git rev-parse --short HEAD || echo "(config) @VERSION@")
  AM_FCFLAGS+=-DCOMMIT='"$(COMMIT)"'
endif

# Clean the modules as well
mostlyclean-local:
	-rm -rf *.mod *.smod

# Modules depend on objects
%.o: %.f90
	@rm -f $@ $(@:.o=.mod) $(@:.o=.smod)
	$(AM_V_PPFC)$(PPFCCOMPILE) -c -o $@ $<
%.o: %.F90
	@rm -f $@ $(@:.o=.mod) $(@:.o=.smod)
	$(AM_V_PPFC)$(PPFCCOMPILE) -c -o $@ $<
%.mod: %.f90
	@rm -f $@ $(@:.mod=.o) $(@:.mod=.smod)
	$(AM_V_PPFC)$(PPFCCOMPILE) -c -o $(@:.mod=.o) $<
%.mod: %.F90
	@rm -f $@ $(@:.mod=.o) $(@:.mod=.smod)
	$(AM_V_PPFC)$(PPFCCOMPILE) -c -o $(@:.mod=.o) $<
%.smod: %.f90
	@rm -f $@ $(@:.smod=.o) $(@:.smod=.mod)
	$(AM_V_PPFC)$(PPFCCOMPILE) -c -o $(@:.smod=.o) $<
%.smod: %.F90
	@rm -f $@ $(@:.smod=.o) $(@:.smod=.mod)
	$(AM_V_PPFC)$(PPFCCOMPILE) -c -o $(@:.smod=.o) $<

# Always recompile the config file to get the compilation details right
config@proc.o : .FORCE

.FORCE: 

# include dependencies (there are only a few, so not generated by makemake)
crystalseedmod@proc.o crystalseedmod@proc.mod crystalseedmod@proc.smod: ciftbx/ciftbx.cmv ciftbx/ciftbx.cmf

#xx# Dependencies: generated by makemake.sh
grid3mod@proc.o grid3mod@proc.smod crystalseedmod@proc.o crystalseedmod@proc.smod : abinit_private.mod
abinit_private@proc.o: abinit_private.smod abinit_private.mod
critic2.o critic2.mod : autocp.mod
autocp@proc.o: autocp.smod autocp.mod
integration@proc.o integration@proc.smod : bader.mod
bader@proc.o: bader.smod bader.mod
critic2.o critic2.mod qtree@proc.o qtree@proc.smod : bisect.mod
bisect@proc.o: bisect.smod bisect.mod
tools_io@proc.o tools_io@proc.smod spglib@proc.o spglib@proc.smod gui_interface.o gui_interface.mod : c_interface_module.mod
global@proc.o global@proc.smod critic2.o critic2.mod gui_interface.o gui_interface.mod : config.mod
yt@proc.o yt@proc.smod xdm@proc.o xdm@proc.smod systemmod.o systemmod.mod systemmod.smod struct_drivers@proc.o struct_drivers@proc.smod struct_drivers.o struct_drivers.mod struct_drivers.smod meshmod@proc.o meshmod@proc.smod meshmod.o meshmod.mod meshmod.smod integration@proc.o integration@proc.smod fieldmod.o fieldmod.mod fieldmod.smod : crystalmod.mod
crystalmod@proc.o: crystalmod.smod crystalmod.mod
systemmod@proc.o systemmod@proc.smod systemmod.o systemmod.mod systemmod.smod struct_drivers@proc.o struct_drivers@proc.smod struct_drivers.o struct_drivers.mod struct_drivers.smod integration@proc.o integration@proc.smod gui_interface.o gui_interface.mod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod autocp@proc.o autocp@proc.smod : crystalseedmod.mod
crystalseedmod@proc.o: crystalseedmod.smod crystalseedmod.mod
fieldmod.o fieldmod.mod fieldmod.smod : dftb_private.mod
dftb_private@proc.o: dftb_private.smod dftb_private.mod
fieldmod.o fieldmod.mod fieldmod.smod : elk_private.mod
elk_private@proc.o: elk_private.smod elk_private.mod
xdm@proc.o xdm@proc.smod wfn_private.o wfn_private.mod wfn_private.smod struct_drivers@proc.o struct_drivers@proc.smod pi_private.o pi_private.mod pi_private.smod meshmod@proc.o meshmod@proc.smod elk_private.o elk_private.mod elk_private.smod dftb_private.o dftb_private.mod dftb_private.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod : environmod.mod
environmod@proc.o: environmod.smod environmod.mod
molcalc@proc.o molcalc@proc.smod critic2.o critic2.mod arithmetic@proc.o arithmetic@proc.smod xdm@proc.o xdm@proc.smod systemmod@proc.o systemmod@proc.smod systemmod.o systemmod.mod systemmod.smod stm@proc.o stm@proc.smod rhoplot@proc.o rhoplot@proc.smod qtree@proc.o qtree@proc.smod nci@proc.o nci@proc.smod meshmod@proc.o meshmod@proc.smod meshmod.o meshmod.mod meshmod.smod integration@proc.o integration@proc.smod integration.o integration.mod integration.smod hirshfeld@proc.o hirshfeld@proc.smod flux@proc.o flux@proc.smod bisect@proc.o bisect@proc.smod autocp@proc.o autocp@proc.smod : fieldmod.mod
fieldmod@proc.o: fieldmod.smod fieldmod.mod
systemmod@proc.o systemmod@proc.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod : fieldseedmod.mod
fieldseedmod@proc.o: fieldseedmod.smod fieldseedmod.mod
critic2.o critic2.mod : flux.mod
flux@proc.o: flux.smod flux.mod
nci@proc.o nci@proc.smod nci.o nci.mod nci.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod environmod@proc.o environmod@proc.smod environmod.o environmod.mod environmod.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod : fragmentmod.mod
fragmentmod@proc.o: fragmentmod.smod fragmentmod.mod
molcalc@proc.o molcalc@proc.smod critic2.o critic2.mod arithmetic@proc.o arithmetic@proc.smod xdm@proc.o xdm@proc.smod systemmod@proc.o systemmod@proc.smod surface@proc.o surface@proc.smod struct_drivers@proc.o struct_drivers@proc.smod stm@proc.o stm@proc.smod rhoplot@proc.o rhoplot@proc.smod quadpack.o quadpack.mod qtree_utils@proc.o qtree_utils@proc.smod qtree_tetrawork@proc.o qtree_tetrawork@proc.smod qtree_gpaths@proc.o qtree_gpaths@proc.smod qtree_basic@proc.o qtree_basic@proc.smod qtree_basic.o qtree_basic.mod qtree_basic.smod qtree@proc.o qtree@proc.smod qtree.o qtree.mod qtree.smod pi_private@proc.o pi_private@proc.smod nci@proc.o nci@proc.smod integration@proc.o integration@proc.smod gui_interface.o gui_interface.mod grid1mod@proc.o grid1mod@proc.smod flux@proc.o flux@proc.smod fieldseedmod@proc.o fieldseedmod@proc.smod fieldmod@proc.o fieldmod@proc.smod environmod@proc.o environmod@proc.smod environmod.o environmod.mod environmod.smod crystalseedmod@proc.o crystalseedmod@proc.smod crystalmod@proc.o crystalmod@proc.smod bisect@proc.o bisect@proc.smod autocp@proc.o autocp@proc.smod : global.mod
integration@proc.o integration@proc.smod flux@proc.o flux@proc.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod bisect@proc.o bisect@proc.smod autocp@proc.o autocp@proc.smod : graphics.mod
graphics@proc.o: graphics.smod graphics.mod
critic2.o critic2.mod arithmetic@proc.o arithmetic@proc.smod xdm@proc.o xdm@proc.smod struct_drivers@proc.o struct_drivers@proc.smod pi_private.o pi_private.mod pi_private.smod nci@proc.o nci@proc.smod hirshfeld@proc.o hirshfeld@proc.smod gui_interface.o gui_interface.mod fieldmod@proc.o fieldmod@proc.smod environmod@proc.o environmod@proc.smod dftb_private.o dftb_private.mod dftb_private.smod crystalmod@proc.o crystalmod@proc.smod : grid1mod.mod
grid1mod@proc.o: grid1mod.smod grid1mod.mod
xdm@proc.o xdm@proc.smod rhoplot@proc.o rhoplot@proc.smod integration@proc.o integration@proc.smod hirshfeld@proc.o hirshfeld@proc.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod : grid3mod.mod
grid3mod@proc.o: grid3mod.smod grid3mod.mod
param.o param.mod arithmetic@proc.o arithmetic@proc.smod systemmod.o systemmod.mod systemmod.smod spglib@proc.o spglib@proc.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod crystalseedmod@proc.o crystalseedmod@proc.smod : hashmod.mod
hashmod@proc.o: hashmod.smod hashmod.mod
critic2.o critic2.mod : hirshfeld.mod
hirshfeld@proc.o: hirshfeld.smod hirshfeld.mod
critic2.o critic2.mod qtree@proc.o qtree@proc.smod bisect@proc.o bisect@proc.smod : integration.mod
integration@proc.o: integration.smod integration.mod
qtree_utils@proc.o qtree_utils@proc.smod qtree@proc.o qtree@proc.smod : keast.mod
molcalc@proc.o molcalc@proc.smod global@proc.o global@proc.smod xdm@proc.o xdm@proc.smod autocp@proc.o autocp@proc.smod : meshmod.mod
meshmod@proc.o: meshmod.smod meshmod.mod
critic2.o critic2.mod : molcalc.mod
critic2.o critic2.mod : nci.mod
nci@proc.o: nci.smod nci.mod
fieldmod.o fieldmod.mod fieldmod.smod : pi_private.mod
pi_private@proc.o: pi_private.smod pi_private.mod
crystalseedmod@proc.o crystalseedmod@proc.smod : qe_private.mod
qe_private@proc.o: qe_private.smod qe_private.mod
critic2.o critic2.mod : qtree.mod
qtree@proc.o: qtree.smod qtree.mod
qtree_utils@proc.o qtree_utils@proc.smod qtree_utils.o qtree_utils.mod qtree_utils.smod qtree_tetrawork@proc.o qtree_tetrawork@proc.smod qtree_tetrawork.o qtree_tetrawork.mod qtree_tetrawork.smod qtree_gpaths@proc.o qtree_gpaths@proc.smod qtree_gpaths.o qtree_gpaths.mod qtree_gpaths.smod qtree@proc.o qtree@proc.smod : qtree_basic.mod
qtree_basic@proc.o: qtree_basic.smod qtree_basic.mod
qtree_tetrawork@proc.o qtree_tetrawork@proc.smod : qtree_gpaths.mod
qtree_gpaths@proc.o: qtree_gpaths.smod qtree_gpaths.mod
qtree@proc.o qtree@proc.smod : qtree_tetrawork.mod
qtree_tetrawork@proc.o: qtree_tetrawork.smod qtree_tetrawork.mod
qtree@proc.o qtree@proc.smod : qtree_utils.mod
qtree_utils@proc.o: qtree_utils.smod qtree_utils.mod
integration@proc.o integration@proc.smod : quadpack.mod
critic2.o critic2.mod : rhoplot.mod
rhoplot@proc.o: rhoplot.smod rhoplot.mod
global@proc.o global@proc.smod critic2.o critic2.mod struct_drivers@proc.o struct_drivers@proc.smod crystalseedmod@proc.o crystalseedmod@proc.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod : spglib.mod
spglib@proc.o: spglib.smod spglib.mod
critic2.o critic2.mod : stm.mod
stm@proc.o: stm.smod stm.mod
critic2.o critic2.mod nci@proc.o nci@proc.smod autocp@proc.o autocp@proc.smod : struct_drivers.mod
struct_drivers@proc.o: struct_drivers.smod struct_drivers.mod
qtree_basic@proc.o qtree_basic@proc.smod qtree@proc.o qtree@proc.smod integration@proc.o integration@proc.smod integration.o integration.mod integration.smod graphics@proc.o graphics@proc.smod graphics.o graphics.mod graphics.smod bisect@proc.o bisect@proc.smod bisect.o bisect.mod bisect.smod autocp@proc.o autocp@proc.smod : surface.mod
surface@proc.o: surface.smod surface.mod
molcalc@proc.o molcalc@proc.smod critic2.o critic2.mod arithmetic@proc.o arithmetic@proc.smod yt@proc.o yt@proc.smod yt.o yt.mod yt.smod xdm@proc.o xdm@proc.smod struct_drivers@proc.o struct_drivers@proc.smod struct_drivers.o struct_drivers.mod struct_drivers.smod stm@proc.o stm@proc.smod rhoplot@proc.o rhoplot@proc.smod quadpack.o quadpack.mod qtree_utils@proc.o qtree_utils@proc.smod qtree_tetrawork@proc.o qtree_tetrawork@proc.smod qtree_gpaths@proc.o qtree_gpaths@proc.smod qtree_basic@proc.o qtree_basic@proc.smod qtree@proc.o qtree@proc.smod nci@proc.o nci@proc.smod integration@proc.o integration@proc.smod integration.o integration.mod integration.smod hirshfeld@proc.o hirshfeld@proc.smod gui_interface.o gui_interface.mod flux@proc.o flux@proc.smod bisect@proc.o bisect@proc.smod bisect.o bisect.mod bisect.smod bader@proc.o bader@proc.smod bader.o bader.mod bader.smod autocp@proc.o autocp@proc.smod : systemmod.mod
systemmod@proc.o: systemmod.smod systemmod.mod
wfn_private@proc.o wfn_private@proc.smod yt@proc.o yt@proc.smod integration@proc.o integration@proc.smod fieldmod@proc.o fieldmod@proc.smod environmod@proc.o environmod@proc.smod elk_private@proc.o elk_private@proc.smod crystalmod@proc.o crystalmod@proc.smod bisect@proc.o bisect@proc.smod autocp@proc.o autocp@proc.smod : tools.mod
tools@proc.o: tools.smod tools.mod
wfn_private@proc.o wfn_private@proc.smod molcalc@proc.o molcalc@proc.smod global@proc.o global@proc.smod critic2.o critic2.mod arithmetic@proc.o arithmetic@proc.smod yt@proc.o yt@proc.smod xdm@proc.o xdm@proc.smod wien_private@proc.o wien_private@proc.smod tools_math@proc.o tools_math@proc.smod tools_math@lebedev.o tools_math@lebedev.smod tools_math.o tools_math.mod tools_math.smod tools@proc.o tools@proc.smod systemmod@proc.o systemmod@proc.smod systemmod.o systemmod.mod systemmod.smod surface@proc.o surface@proc.smod struct_drivers@proc.o struct_drivers@proc.smod stm@proc.o stm@proc.smod spglib@proc.o spglib@proc.smod rhoplot@proc.o rhoplot@proc.smod qtree_utils@proc.o qtree_utils@proc.smod qtree_tetrawork@proc.o qtree_tetrawork@proc.smod qtree_gpaths@proc.o qtree_gpaths@proc.smod qtree_basic@proc.o qtree_basic@proc.smod qtree@proc.o qtree@proc.smod pi_private@proc.o pi_private@proc.smod nci@proc.o nci@proc.smod meshmod@proc.o meshmod@proc.smod integration@proc.o integration@proc.smod hirshfeld@proc.o hirshfeld@proc.smod gui_interface.o gui_interface.mod grid3mod@proc.o grid3mod@proc.smod grid1mod@proc.o grid1mod@proc.smod graphics@proc.o graphics@proc.smod fragmentmod@proc.o fragmentmod@proc.smod flux@proc.o flux@proc.smod fieldseedmod@proc.o fieldseedmod@proc.smod fieldmod@proc.o fieldmod@proc.smod environmod@proc.o environmod@proc.smod elk_private@proc.o elk_private@proc.smod dftb_private@proc.o dftb_private@proc.smod crystalseedmod@proc.o crystalseedmod@proc.smod crystalmod@proc.o crystalmod@proc.smod bisect@proc.o bisect@proc.smod bader@proc.o bader@proc.smod autocp@proc.o autocp@proc.smod abinit_private@proc.o abinit_private@proc.smod : tools_io.mod
wfn_private@proc.o wfn_private@proc.smod arithmetic@proc.o arithmetic@proc.smod yt@proc.o yt@proc.smod xdm@proc.o xdm@proc.smod wien_private@proc.o wien_private@proc.smod systemmod@proc.o systemmod@proc.smod surface@proc.o surface@proc.smod struct_drivers@proc.o struct_drivers@proc.smod rhoplot@proc.o rhoplot@proc.smod qtree_tetrawork@proc.o qtree_tetrawork@proc.smod qtree_basic@proc.o qtree_basic@proc.smod pi_private@proc.o pi_private@proc.smod nci@proc.o nci@proc.smod meshmod@proc.o meshmod@proc.smod integration@proc.o integration@proc.smod grid3mod@proc.o grid3mod@proc.smod graphics@proc.o graphics@proc.smod fragmentmod@proc.o fragmentmod@proc.smod flux@proc.o flux@proc.smod fieldmod@proc.o fieldmod@proc.smod environmod@proc.o environmod@proc.smod environmod.o environmod.mod environmod.smod elk_private@proc.o elk_private@proc.smod dftb_private@proc.o dftb_private@proc.smod crystalseedmod@proc.o crystalseedmod@proc.smod crystalmod@proc.o crystalmod@proc.smod bisect@proc.o bisect@proc.smod bader@proc.o bader@proc.smod autocp@proc.o autocp@proc.smod : tools_math.mod
tools_math@lebedev.o: tools_math.smod tools_math.mod
tools_math@proc.o: tools_math.smod tools_math.mod
critic2.o critic2.mod : tricks.mod
wfn_private@proc.o wfn_private@proc.smod molcalc@proc.o molcalc@proc.smod arithmetic@proc.o arithmetic@proc.smod yt@proc.o yt@proc.smod yt.o yt.mod yt.smod xdm@proc.o xdm@proc.smod systemmod@proc.o systemmod@proc.smod systemmod.o systemmod.mod systemmod.smod struct_drivers@proc.o struct_drivers@proc.smod spglib@proc.o spglib@proc.smod rhoplot@proc.o rhoplot@proc.smod qtree_tetrawork@proc.o qtree_tetrawork@proc.smod qtree_gpaths@proc.o qtree_gpaths@proc.smod qtree_gpaths.o qtree_gpaths.mod qtree_gpaths.smod qtree_basic@proc.o qtree_basic@proc.smod qtree@proc.o qtree@proc.smod nci@proc.o nci@proc.smod meshmod@proc.o meshmod@proc.smod integration@proc.o integration@proc.smod integration.o integration.mod integration.smod grid3mod@proc.o grid3mod@proc.smod grid1mod@proc.o grid1mod@proc.smod graphics@proc.o graphics@proc.smod fragmentmod@proc.o fragmentmod@proc.smod fragmentmod.o fragmentmod.mod fragmentmod.smod flux@proc.o flux@proc.smod fieldseedmod@proc.o fieldseedmod@proc.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod environmod@proc.o environmod@proc.smod environmod.o environmod.mod environmod.smod dftb_private@proc.o dftb_private@proc.smod dftb_private.o dftb_private.mod dftb_private.smod crystalseedmod@proc.o crystalseedmod@proc.smod crystalseedmod.o crystalseedmod.mod crystalseedmod.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod bisect@proc.o bisect@proc.smod bader@proc.o bader@proc.smod bader.o bader.mod bader.smod autocp@proc.o autocp@proc.smod : types.mod
types@proc.o: types.smod types.mod
molcalc@proc.o molcalc@proc.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod crystalseedmod@proc.o crystalseedmod@proc.smod : wfn_private.mod
fieldmod.o fieldmod.mod fieldmod.smod : wien_private.mod
wien_private@proc.o: wien_private.smod wien_private.mod
critic2.o critic2.mod : xdm.mod
xdm@proc.o: xdm.smod xdm.mod
integration@proc.o integration@proc.smod : yt.mod
yt@proc.o: yt.smod yt.mod
molcalc@proc.o molcalc@proc.smod global@proc.o global@proc.smod critic2.o critic2.mod yt@proc.o yt@proc.smod systemmod@proc.o systemmod@proc.smod rhoplot@proc.o rhoplot@proc.smod grid3mod@proc.o grid3mod@proc.smod fieldmod@proc.o fieldmod@proc.smod crystalseedmod@proc.o crystalseedmod@proc.smod bader@proc.o bader@proc.smod : arithmetic.mod
arithmetic@proc.o: arithmetic.smod arithmetic.mod
config@proc.o: config.smod config.mod
global@proc.o: global.smod global.mod
molcalc@proc.o: molcalc.smod molcalc.mod
wfn_private@proc.o wfn_private@proc.smod tools_io@proc.o tools_io@proc.smod molcalc@proc.o molcalc@proc.smod global@proc.o global@proc.smod critic2.o critic2.mod arithmetic@proc.o arithmetic@proc.smod arithmetic.o arithmetic.mod arithmetic.smod yt@proc.o yt@proc.smod xdm@proc.o xdm@proc.smod wien_private@proc.o wien_private@proc.smod types.o types.mod types.smod tools_math@proc.o tools_math@proc.smod tools_math@lebedev.o tools_math@lebedev.smod tools_io.o tools_io.mod tools_io.smod systemmod@proc.o systemmod@proc.smod surface@proc.o surface@proc.smod struct_drivers@proc.o struct_drivers@proc.smod stm@proc.o stm@proc.smod rhoplot@proc.o rhoplot@proc.smod quadpack.o quadpack.mod qtree_utils@proc.o qtree_utils@proc.smod qtree_utils.o qtree_utils.mod qtree_utils.smod qtree_basic@proc.o qtree_basic@proc.smod pi_private@proc.o pi_private@proc.smod pi_private.o pi_private.mod pi_private.smod nci@proc.o nci@proc.smod meshmod@proc.o meshmod@proc.smod integration@proc.o integration@proc.smod gui_interface.o gui_interface.mod grid3mod@proc.o grid3mod@proc.smod grid3mod.o grid3mod.mod grid3mod.smod grid1mod@proc.o grid1mod@proc.smod graphics@proc.o graphics@proc.smod graphics.o graphics.mod graphics.smod global.o global.mod global.smod fragmentmod@proc.o fragmentmod@proc.smod flux@proc.o flux@proc.smod fieldseedmod@proc.o fieldseedmod@proc.smod fieldseedmod.o fieldseedmod.mod fieldseedmod.smod fieldmod@proc.o fieldmod@proc.smod fieldmod.o fieldmod.mod fieldmod.smod environmod@proc.o environmod@proc.smod environmod.o environmod.mod environmod.smod elk_private@proc.o elk_private@proc.smod dftb_private@proc.o dftb_private@proc.smod crystalseedmod@proc.o crystalseedmod@proc.smod crystalseedmod.o crystalseedmod.mod crystalseedmod.smod crystalmod@proc.o crystalmod@proc.smod crystalmod.o crystalmod.mod crystalmod.smod config.o config.mod config.smod bisect@proc.o bisect@proc.smod bader@proc.o bader@proc.smod autocp@proc.o autocp@proc.smod : param.mod
tools_io@proc.o: tools_io.smod tools_io.mod
wfn_private@proc.o: wfn_private.smod wfn_private.mod
