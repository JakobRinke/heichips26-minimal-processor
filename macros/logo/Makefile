all: logo drc
.PHONY: all

logo:
	python3 script/create_gds.py png/nand_logo.png gds/nand_logo.gds --cellname nand_logo --invert --merge --smooth --pixel-size 0.21 --width 130 --height 130 --foreground "50/0"
.PHONY: logo

drc:
#	echo "calma read gds/nand_logo.gds;load nand_logo;lef write -pinonly;" | PDK_ROOT=${PDK_ROOT} PDK=${PDK} magic -rcfile ${PDK_ROOT}/${PDK}/libs.tech/magic/${PDK}.magicrc -dnull -noconsole
#	mv nand_logo.lef lef/
	PDK_ROOT=${PDK_ROOT} PDK=${PDK} klayout -b -zz -r ${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/drc/ihp-sg13cmos5l.drc -rd input=gds/nand_logo.gds -rd report=report.lyrdb -rd feol=false -rd beol=true
.PHONY: drc