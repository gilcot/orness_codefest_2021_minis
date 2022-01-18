#!/bin/sh
# ex: ai:sw=4:ts=4
# vim: ai:ft=sh:sw=4:ts=4:ff=unix:sts=4:et:fenc=utf8
# -*- sh; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4;
# atom: set usesofttabs tabLength=4 encoding=utf-8 lineEnding=lf grammar=shell;
# mode: shell; tabsoft; tab:4; encoding: utf-8; coding: utf-8;
##########################################################################
# https://dojo.codes/campaigns/orness_codefest_2021_minis/participate

for _cmd in grep tr fold sed
do
    command -v $_cmd >/dev/null || exit 222
done

_i_origin_x=0
_i_origin_y=0
OLD_IFS="$IFS"

## Nice display of prompt message to have inputs aligned
# $1: text to format
_do_prompt() {
    printf '%-60s\t' "$1"
}

## Output trace message
# $1: text to format on stderr
_do_notice() {
    echo "DeBuG: $1" >&2
}

_do_prompt "règle de naissance (3,5,6 = 3, 5 ou 6 voisines)"
read -r _l_cond_make _void
echo "$_l_cond_make" | grep -Eqs '^[0-9]+(,[0-9]+)*$' || exit

_do_prompt "règle de survie (2,3 = 2 ou 3 voisines)"
read -r _l_cond_keep _void
echo "$_l_cond_keep" | grep -Eqs '^[0-9]+(,[0-9]+)*$' || exit

_do_prompt "grille initiale: coin haut-gauche (-10,-5 = rangée,colonne)"
IFS=',' read -r _i_corner0_x _i_corner0_y _void
echo "$_i_corner0_x" | grep -Eqs -e '^-?[0-9]+$' || exit
echo "$_i_corner0_y" | grep -Eqs -e '^-?[0-9]+$' || exit

_do_prompt "grille initiale: taille totale (13x7 = large × haut)"
IFS=x read -r _i_size0_w _i_size0_h _void
echo "$_i_size0_w" | grep -Eqs '^[0-9]+$' || exit
echo "$_i_size0_h" | grep -Eqs '^[0-9]+$' || exit

# =doc:md:start
# First, this script use a table to store the initial grid (input part.)
# So will do many scripting languages. But if I had to implement it,
# let's say in C/C++/Go/Pascal/Rust/etc., I would go for chained list
# of active cells because I think it's more memory efficient and also
# faster in some circonstances. OK, but working with a table may look
# easier (less complex) for adjacence matrix of graphs, isn't it?   
# Second, cells in the table are just boolean instead of the given
# couple of characters. It should ease computations later.
# ```
# visual  matrix
# __X___  001000
# ___X__  000100
# _XXX_X  011101
# ```
# Our table/grid should be read as oriented from left to right and from
# top to down, like it should be with any array in any programming langage
# ```
# _i_corner0_x    →  +_i_size0_w
# _i_corner0_y ┌┈ ┬ ┈┐
#              ┊     ┊
#            ↓ ├     ┤
#              ┊     ┊
#  +_i_size0_h └┈ ┴ ┈┘
# ```
# Last but not least, as we're using POSIX shell which lakes array
# (available with: bash, ksh, pdksh, maybe zsh and others I dunno)
# the matrix is represented in a string …without any rows/columns
# delimiters! So, previous example matrix is represented with:
# ```
# 001000000100011101
# ╰1st.╯╰2nd.╯╰3rd.╯ 
# ```
# Hey, wait, aren't we using un-named Jef Poskanzer
# [PBM](https://en.wikipedia.org/wiki/Netpbm#PBM_example)?
# =doc:md:stop

echo "grille initiale: lignes de cellules (x/_ = vivante/morte)"
#printf "\tO = point d'origine 0,0\n\tR = point haut-gauche grill-sortie\n"
_temp_grid=''
_l_cells=' '
_l_mask=$( printf '%*s' $_i_size0_w '' | tr ' ' '_' )
_i_row_count=0
while test $_i_row_count -lt $_i_size0_h
do
    printf ' rangée %i\t' $(( _i_corner0_x + _i_row_count ))
    IFS= read -r _l_cells
    _temp_grid="$_temp_grid$( printf '%s%*.*s' \
        "$_l_cells" 0 $(( _i_size0_w - ${#_l_cells} )) "$_l_mask" |
        cut -c 1-$_i_size0_w | tr '[a-zA-Z1-9]' '1' | tr -d '\r\n' | tr -C 1 0 )"
    _i_row_count=$(( _i_row_count + 1 ))
done
unset _i_row_count _l_cells _l_mask
#_do_notice "part grid: $_temp_grid" #; exit

_do_prompt "génération attendue en sortie (0 = génération de départ)"
IFS=' ' read -r _i_gen_end _void
echo "$_i_gen_end" | grep -Eqs '[0-9]+' || exit

_do_prompt "fenêtre d'affichage: coin haut-gauche (3,3 = rangée,colonne)"
IFS=',' read -r _i_corner1_x _i_corner1_y _void
echo "$_i_corner1_x" | grep -Eqs -e '^-?[0-9]+$' -- || exit
echo "$_i_corner1_y" | grep -Eqs -e '^-?[0-9]+$' -- || exit

_do_prompt "fenêtre d'affichage: coin bas-droite (-4,-1 = rangée,colonne)"
IFS=',' read -r _i_corner2_x _i_corner2_y _void
echo "$_i_corner2_x" | grep -Eqs -e '^-?[0-9]+$' -- || exit
echo "$_i_corner2_y" | grep -Eqs -e '^-?[0-9]+$' -- || exit

# =doc:md:start
# By the same way, the universe viewed part is converted to working table…
# ```
# (_i_corner1_x,_i_corner1_y)
#                  ⇱╌╌╌╌╌┐
#                  ╎     ╎
#                  ╎  ◌  ╎
#                  ╎     ╎
#                  └╌╌╌╌╌⇲
#             (_i_corner2_x,_i_corner2_y)
# ```
# The working table must include the previous one. Two approches:
#   * Create a mask/empty table (it's like doing `pbmmake -white`) and then
#     put/include the previous table in it (in the given coordinates)
#   * Extend the previous table in all directions to match the final canvas
#     (a bit like playing with `pnmmargin -white` is easier cases, or like
#     like using `pnmpad -white` in general)
# The choice will depend on the underlying algorithm cost.
# ```
#  ⇱╌╌╌╌╌╌╌╌╌┐
#  ╎         ╎
#  ╎         ╎
#  ╎  ┌┈┈┈┈┐ ╎
#  ╎  ┊ ◌  ┊ ╎
#  ╎  ┊    ┊ ╎
#  ╎  └┈┈┈┈┘ ╎
#  ╎         ╎
#  └╌╌╌╌╌╌╌╌╌⇲
# ```
# Note that in our case, the canvas must really include the initial grid,
# even if we have to enlarge the view port (and cut it at end but this is
# more work and information to store) or trigger an error (as there's
# something wrong here don't you agree?)
# ```
#  ⇱╌╌╌╌╌╌╌╌╌┐
#  ╎         ╎
#  ╎         ╎
#  ╎     ┌┈┈┈╎┈┐
#  ╎    ◌┊   ╎ ┊
#  ╎     ┊   ╎ ┊
#  ╎     └┈┈┈╎┈┘
#  ╎         ╎
#  └╌╌╌╌╌╌╌╌╌⇲
# ```
# =doc:md:stop

if test $_i_corner1_x -lt $_i_corner2_x &&
    test $_i_corner1_y -lt $_i_corner2_y
then
    #_do_notice "swap ($_i_corner1_x,$_i_corner1_y) & ($_i_corner2_x,$_i_corner2_y)"
    _i_row_count=$_i_corner2_y
    _i_corner2_y=$_i_corner1_y
    _i_corner1_y=$_i_row_count
    # should read as _i_col_count
    _i_row_count=$_i_corner2_x
    _i_corner2_x=$_i_corner1_x
    _i_corner1_x=$_i_row_count
    #_do_notice "done ($_i_corner1_x,$_i_corner1_y) & ($_i_corner2_x,$_i_corner2_y)"
fi

_i_row_count=$(( _i_corner2_y - _i_corner1_y ))
_i_row_count=${_i_row_count#-}
# bash/ksh93/etc. have abs function but that's not POSIX
_i_size1_h=$(( _i_row_count > _i_size0_h ? _i_row_count : _i_size0_h ))

_i_row_count=$(( _i_corner2_x - _i_corner1_x ))
# it's column but recycling variable
_i_row_count=${_i_row_count#-}
_i_size1_w=$(( _i_row_count > _i_size0_w ? _i_row_count : _i_size0_w ))

if test $_i_corner1_y -lt $_i_corner2_y
then
    _i_row_pos=$_i_corner1_y
    _i_row_end=$_i_corner2_y
else
    _i_row_pos=$_i_corner2_y
    _i_row_end=$_i_corner1_y
fi

_i_col_padL=$(( _i_corner1_x > _i_corner0_x ? _i_corner1_x - _i_corner0_x : _i_corner0_x - _i_corner1_x ))
_i_col_padR=$(( _i_size1_w - _i_size0_w - _i_col_padL ))
#_do_notice "padding L-R=$_i_col_padL-$_i_col_padR"

_last_grid=''
_i_row_count=0
#_do_notice "lines from $_i_row_pos to $_i_row_end"
while test $_i_row_pos -le $_i_row_end
do
    test $_i_row_pos -eq 0 &&
        _i_origin_y=$_i_row_count
    if test $_i_row_pos -lt $_i_corner0_y ||
        test $_i_row_pos -ge $(( _i_corner0_y + _i_size0_h ))
    then
        #_do_notice "at row $_i_row_count for $_i_row_pos with nothing"
        _last_grid="$_last_grid$( printf '%0*d' $_i_size1_w 0 )"
    else
        _i_sub_index=$(( _i_size0_w * (_i_row_count - _i_size0_h) + 1 ))
        #_do_notice "at row $_i_row_count for $_i_row_pos with $_i_sub_index"
        test $_i_col_padL -gt 0 &&
            _last_grid="$_last_grid$( printf '%0*d' $_i_col_padL 0 )"
        _last_grid="$_last_grid$( echo "$_temp_grid" |
            cut -c $_i_sub_index-$(( _i_sub_index + _i_size0_w - 1 )) )"
        test $_i_col_padR -gt 0 &&
            _last_grid="$_last_grid$( printf '%0*d' $_i_col_padR 0 )"
    fi
    #_do_notice "currently: $_last_grid"
    _i_row_count=$(( _i_row_count + 1 ))
    _i_row_pos=$(( _i_row_pos + 1 ))
done
unset _i_col_padL _i_col_padR
unset _i_corner0_x _i_corner0_y _i_size0_h _i_size0_w _temp_grid
#unset _i_corner1_y _i_corner2_y
#_do_notice "last grid: $_last_grid" ; exit

if test $_i_corner1_x -lt $_i_corner2_x
then
    _i_row_pos=$_i_corner1_x
    _i_row_end=$_i_corner2_x
else
    _i_row_pos=$_i_corner2_x
    _i_row_end=$_i_corner1_x
fi
#_do_notice "columns from $_i_row_pos to $_i_row_end"
_i_row_count=0
while test $_i_row_pos -le $_i_row_end
do
    test $_i_row_pos -eq 0 &&
        _i_origin_x=$_i_row_count
    _i_row_pos=$(( _i_row_pos + 1 ))
    _i_row_count=$(( _i_row_count + 1 ))
done
unset _i_row_count _i_row_end _i_row_pos
#unset _i_corner1_x _i_corner2_x

# =doc:md:start
# In order to evaluate the conditions lists (i.e. `_l_cond_make` and 
# for birth/newborn/creation and `_l_cond_keep` for saving/survival)
# we must evaluate each cell's Moore neighborhood (read for example
# [Eric Wolfgang Weisstein @ MathWorld.Wolfram.com](https://mathworld.wolfram.com/MooreNeighborhood.html)
# and [Tim Tyler @ Cell-Auto.com](http://cell-auto.com/neighbourhood/moore/)
# etc.) So, for any position CC (i.e. Current Cell) using
# [cardinal letters](https://www.btb.termiumplus.gc.ca/tpv2guides/guides/clefsfp/index-fra.html?lang=fra&lettr=indx_catlog_p&page=9NsHl9aZIekU.html)
# ```
# NW NN NE
# WW CC EE
# SW SS SE
# ```
# Using the already explained array coordinates, previous picture becomes
# with CC located at current `(row,column)` and `-1`/`+1` for previous/next
# ```
# (c-1,r-1) (c±0,r-1) (c+1,r-1)
# (c-1,r±0) (c±0,r±0) (c+1,r±0)
# (c-1,r+1) (c±0,r+1) (c+1,r+1)
# ```
# The weight of the neighborhood is givent by the sum of that neighborhood
# cells value (hence the advantage of the boolean representation as `1`/`0`
# for alive/dead: no extra convertion needed) Boundaries are always seen as
# dead cell (weird, our grid isn't an infinite universe…)
# =doc:md:stop

_i_gen_count=0
while test $_i_gen_count -le $_i_gen_end
do
    _do_notice "turn $_i_gen_count:"
    _i_gen_count=$(( _i_gen_count + 1 ))
    echo "$_last_grid" | sed -e "s/.\\{$_i_size1_w\\}/&\\n/g" | tr '10' 'x_'
    _i_cell_count=0
    _temp_grid=''
    for _i_cell_value in $( echo "$_last_grid" | fold -w 1 )
    do
        _i_cell_c=$(( _i_cell_count % (_i_size1_w + 1) + 1 ))
        _i_cell_r=$(( (_i_cell_count - _i_cell_c + 1) / _i_size1_w ))
        #_do_notice "$_i_cell_count# ($_i_cell_r,$_i_cell_c) = $_i_cell_value"
        # internal ksh/bash: echo ${var:start_index:length}
        # external posix undef...: expr $var star_index length
        # externals posix ok...: echo $var | head -c start_index | tail -c length+1
        # external posix fine...: echo $var | cut -c start_index
        #_do_notice "gen=$_i_gen_count,pos=$_i_cell_count,val=$_i_cell_value"
        if test $_i_cell_c -eq 0 || test $_i_cell_r -eq 0
        then
            __nw=0
        else # @(c-1,r-1)
            #_do_notice "at NW"
            __nw=$( echo "$_last_grid" |
                cut -c $(( _i_cell_r * _i_size1_w + _i_cell_c - 1 )) )
        fi
        if test $_i_cell_r -eq 0
        then
            __nn=0
        else # @(c±0,r-1)
            #_do_notice "at NN"
            __nn=$( echo "$_last_grid" |
                cut -c $(( _i_cell_r * _i_size1_w + _i_cell_c )) )
        fi
        if test $_i_cell_c -eq $_i_size1_w || test $_i_cell_r -eq 0
        then
            __ne=0
        else # @(c+1,r-1)
            #_do_notice "at NE"
            __ne=$( echo "$_last_grid" |
                cut -c $(( _i_cell_r * _i_size1_w + _i_cell_c + 1 )) )
        fi
        if test $_i_cell_c -eq 0 || test $_i_cell_count -le 1
        then
            __ww=0
        else # @(c-1,r±0)
            #_do_notice "at WW"
            __ww=$( echo "$_last_grid" |
                cut -c $(( _i_cell_count - 1 )) )
        fi
        if test $_i_cell_c -eq $_i_size1_w
        then
            __ee=0
        else # @(c+1,r±0)
            #_do_notice "at EE"
            __ee=$( echo "$_last_grid" |
                cut -c $(( _i_cell_count + 1 )) )
        fi
        if test $_i_cell_c -eq 0 || test $_i_cell_r -eq $_i_size1_h
        then
            __sw=0
        else # @(c-1,r+1)
            #_do_notice "at SW"
            __sw=$( echo "$_last_grid" |
                cut -c $(( _i_size1_w * (_i_cell_r + 1) + _i_cell_c - 1 )) )
        fi
        if test $_i_cell_r -eq $_i_size1_h
        then
            __ss=0
        else # @(c±0,r+1)
            #_do_notice "at SS"
            __ss=$( echo "$_last_grid" |
                cut -c $(( _i_size1_w * (_i_cell_r + 1) + _i_cell_c )) )
        fi
        if test $_i_cell_c -eq $_i_size1_w || test $_i_cell_r -eq $_i_size1_h
        then
            __se=0
        else # @(c+1,r+1)
            #_do_notice "at SE"
            __se=$( echo "$_last_grid" |
                cut -c $(( _i_size1_w * (_i_cell_r + 1) + _i_cell_c + 1 )) )
        fi
        _i_cell_weight=$(( __nw + __nn + __ne + __ww + __ee + __sw + __ss + __se ))
        if echo "$_l_cond_keep" | grep -qs "$_i_cell_weight"
        then
            _temp_grid="$_temp_grid$_i_cell_value"
        elif echo "$_l_cond_make" | grep -qs "$_i_cell_weight"
        then
            _temp_grid="${_temp_grid}1"
        else
            _temp_grid="${_temp_grid}0"
        fi
        _i_cell_count=$(( _i_cell_count + 1 ))
    done
    _last_grid="$_temp_grid"
done
