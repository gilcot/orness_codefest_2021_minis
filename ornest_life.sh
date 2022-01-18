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
# $1: text to format on stdin
_do_prompt() {
    printf '%-60s\t' "$1"
}

## Output trace message on verbose mode
# $1: debug/warning/notice level
# $2: text to format on stderr
_do_notice() {
    test $(( DEBUG )) -ge $1 &&
        echo "DeBuG$1: $2" >&2
}

## Pretty print the grid
# $1: string of internal representation ($_l_grid_last)
# $2: displayed image real width ($_i_size1_w)
# $3: line separator (default pipe, escape slash with backslash)
# $4: alive-dead characters pair (default "x"-"_") for standard cells
# $5: alive-dead characters pair (default "X"-"O") for origin only
_do_mapout() {
    _i_cell_n=$(( _i_origin_y * ${2} + _i_origin_x ))
    if test $_i_cell_n -eq 0
    then
        echo "$1" | sed -e "s/.\\{$2\\}/&${3:-|}/g" | tr '10' "${4:-x_}"
    else
        _i_cell_v=$( echo "$1" | cut -c $_i_cell_n | tr '10' "${5:-XO}" )
        echo "$1" | sed "s/./$_i_cell_v/$_i_cell_n" |
            sed -e "s/.\\{$2\\}/&${3:-|}/g" | tr '10' "${4:-x_}"
    fi
}

if test -n "$1"
then
    _do_notice 2 "liste nombre voisins pour nouveau: $1"
    _l_cond_make="$1"
    shift
else
    _do_prompt "règle de naissance (3,5,6 = 3, 5 ou 6 voisines)"
    read -r _l_cond_make _void
fi
echo "$_l_cond_make" | grep -Eqs '^[0-9]+(,[0-9]+)*$' || exit

if test -n "$1"
then
    _do_notice 2 "liste nombre voisins pour survie: $1"
    _l_cond_keep="$1"
    shift
else
    _do_prompt "règle de survie (2,3 = 2 ou 3 voisines)"
    read -r _l_cond_keep _void
fi
echo "$_l_cond_keep" | grep -Eqs '^[0-9]+(,[0-9]+)*$' || exit

if test -n "$1"
then
    _do_notice 2 "coin entrée haut-gauche : ($1)"
    _i_corner0_x=$( echo "$1" | cut -d ',' -f 1 )
    _i_corner0_y=$( echo "$1" | cut -d ',' -f 2 )
    shift
else
    _do_prompt "grille initiale: coin haut-gauche (-10,-5 = rangée,colonne)"
    IFS=',' read -r _i_corner0_x _i_corner0_y _void
fi
echo "$_i_corner0_x" | grep -Eqs -e '^-?[0-9]+$' || exit
echo "$_i_corner0_y" | grep -Eqs -e '^-?[0-9]+$' || exit

if test -n "$1"
then
    _do_notice 2 "grille initiale taille : $1"
    _i_size0_w=$( echo "$1" | cut -d 'x' -f 1 )
    _i_size0_h=$( echo "$1" | cut -d 'x' -f 2 )
    shift
else
    _do_prompt "grille initiale: taille totale (13x7 = large × haut)"
    IFS=×xX* read -r _i_size0_w _i_size0_h _void
fi
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

_l_grid_temp=''
_l_mask=$( printf '%*s' $_i_size0_w '' | tr ' ' '_' )
_i_row_num=0
if test $# -ge $_i_size0_h
then
    _do_notice 2 "grille initiale lignes :"
    while test $_i_row_num -lt $_i_size0_h
    do
        _do_notice 2 " rangée $(( _i_corner0_x + _i_row_num )) = $1"
        _l_grid_temp="$_l_grid_temp$( printf '%s%*.*s' \
            "$1" 0 $(( _i_size0_w - ${#1} )) "$_l_mask" |
            cut -c 1-$_i_size0_w | tr '[a-zA-Z1-9]' '1' |
            tr -d '\r\n' | tr -C 1 0 )"
        _i_row_num=$(( _i_row_num + 1 ))
        shift
    done
else
    _l_cells=' '
    echo "grille initiale: lignes de cellules (x/_ = vivante/morte)"
    while test $_i_row_num -lt $_i_size0_h
    do
        printf ' rangée %i\t' $(( _i_corner0_x + _i_row_num ))
        IFS= read -r _l_cells
        _l_grid_temp="$_l_grid_temp$( printf '%s%*.*s' \
            "$_l_cells" 0 $(( _i_size0_w - ${#_l_cells} )) "$_l_mask" |
            cut -c 1-$_i_size0_w | tr '[a-zA-Z1-9]' '1' |
            tr -d '\r\n' | tr -C 1 0 )"
        _i_row_num=$(( _i_row_num + 1 ))
    done
fi
unset _i_row_num _l_cells _l_mask
_do_notice 3 "part grid: $_l_grid_temp" #; exit

if test -n "$1"
then
    _do_notice 2 "génération finale attendue : $1"
    _i_gen_end="$1"
    shift
else
    _do_prompt "génération attendue en sortie (0 = génération de départ)"
    IFS=' ' read -r _i_gen_end _void
fi
echo "$_i_gen_end" | grep -Eqs '^[0-9]+$' || exit

if test -n "$1"
then
    _do_notice 2 "coin sortie haut-gauche : ($1)"
    _i_corner1_x=$( echo "$1" | cut -d ',' -f 1 )
    _i_corner1_y=$( echo "$1" | cut -d ',' -f 2 )
    shift
else
    _do_prompt "fenêtre d'affichage: coin haut-gauche (3,3 = rangée,colonne)"
    IFS=',' read -r _i_corner1_x _i_corner1_y _void
fi
echo "$_i_corner1_x" | grep -Eqs -e '^-?[0-9]+$' -- || exit
echo "$_i_corner1_y" | grep -Eqs -e '^-?[0-9]+$' -- || exit

if test -n "$1"
then
    _do_notice 2 "coin sortie bas-droite : ($1)"
    _i_corner2_x=$( echo "$1" | cut -d ',' -f 1 )
    _i_corner2_y=$( echo "$1" | cut -d ',' -f 2 )
    shift
else
    _do_prompt "fenêtre d'affichage: coin bas-droite (-4,-1 = rangée,colonne)"
    IFS=',' read -r _i_corner2_x _i_corner2_y _void
fi
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

if test $_i_corner1_x -gt $_i_corner2_x &&
    test $_i_corner1_y -gt $_i_corner2_y
then
    _do_notice 3 "swap ($_i_corner1_x,$_i_corner1_y) & ($_i_corner2_x,$_i_corner2_y)"
    _i_row_num=$_i_corner2_y
    _i_corner2_y=$_i_corner1_y
    _i_corner1_y=$_i_row_num
    # should read as _i_col_count
    _i_row_num=$_i_corner2_x
    _i_corner2_x=$_i_corner1_x
    _i_corner1_x=$_i_row_num
    _do_notice 4 "done ($_i_corner1_x,$_i_corner1_y) & ($_i_corner2_x,$_i_corner2_y)"
fi

_i_row_num=$(( _i_corner2_y - _i_corner1_y ))
_i_row_num=${_i_row_num#-}
# bash/ksh93/etc. have abs function but that's not POSIX
_i_size1_h=$(( _i_row_num > _i_size0_h ? _i_row_num + 1 : _i_size0_h ))

_i_row_num=$(( _i_corner2_x - _i_corner1_x ))
# it's column but recycling variable
_i_row_num=${_i_row_num#-}
_i_size1_w=$(( _i_row_num > _i_size0_w ? _i_row_num + 1 : _i_size0_w ))

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
_do_notice 3 "padding L-R=$_i_col_padL-$_i_col_padR"

_l_grid_last=''
_i_row_num=0
_do_notice 2 "lines from $_i_row_pos to $_i_row_end"
while test $_i_row_pos -le $_i_row_end
do
    test $_i_row_pos -eq 0 &&
        _i_origin_y=$_i_row_num
    if test $_i_row_pos -lt $_i_corner0_y ||
        test $_i_row_pos -ge $(( _i_corner0_y + _i_size0_h ))
    then
        _do_notice 3 "at row $_i_row_num for $_i_row_pos with nothing"
        _l_grid_last="$_l_grid_last$( printf '%0*d' $_i_size1_w 0 )"
    else
        _i_sub_index=$(( _i_size0_w * (_i_row_pos - _i_corner0_y) + 1 ))
        _do_notice 3 "at row $_i_row_num for $_i_row_pos with $_i_sub_index"
        test $_i_col_padL -gt 0 &&
            _l_grid_last="$_l_grid_last$( printf '%0*d' $_i_col_padL 0 )"
        _l_grid_last="$_l_grid_last$( echo "$_l_grid_temp" |
            cut -c $_i_sub_index-$(( _i_sub_index + _i_size0_w - 1 )) )"
        test $_i_col_padR -gt 0 &&
            _l_grid_last="$_l_grid_last$( printf '%0*d' $_i_col_padR 0 )"
    fi
    _do_notice 4 "currently: $_l_grid_last"
    _i_row_num=$(( _i_row_num + 1 ))
    _i_row_pos=$(( _i_row_pos + 1 ))
done
unset _i_col_padL _i_col_padR
unset _i_corner0_x _i_corner0_y _i_size0_h _i_size0_w _l_grid_temp
#unset _i_corner1_y _i_corner2_y
_do_notice 2 "last grid: $_l_grid_last"

if test $_i_corner1_x -lt $_i_corner2_x
then
    _i_row_pos=$_i_corner1_x
    _i_row_end=$_i_corner2_x
else
    _i_row_pos=$_i_corner2_x
    _i_row_end=$_i_corner1_x
fi
_do_notice 2 "columns from $_i_row_pos to $_i_row_end"
_i_row_num=0
while test $_i_row_pos -le $_i_row_end
do
    test $_i_row_pos -eq 0 &&
        _i_origin_x=$_i_row_num
    _i_row_pos=$(( _i_row_pos + 1 ))
    _i_row_num=$(( _i_row_num + 1 ))
done
unset _i_row_num _i_row_end _i_row_pos
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
while test $_i_gen_count -lt $_i_gen_end
do
    _do_notice 1 "turn $_i_gen_count="
    _i_gen_count=$(( _i_gen_count + 1 ))
    test $(( DEBUG )) -ge 1 &&
        _do_mapout "$_l_grid_last" $_i_size1_w '\n'
    _i_cell_n=0
    _i_cell_r=0
    _l_grid_temp=''
    for _l_grid_line in $( printf '%s' "$_l_grid_last" | fold -w $_i_size1_w )
    do
        _do_notice 2 "r$_i_cell_r= $_l_grid_line"
        for _i_cell_v in $( printf '%s' "$_l_grid_line" | fold -w 1 )
        do
            _i_cell_c=$(( _i_cell_n % _i_size1_w ))
            _i_cell_n=$(( _i_cell_n + 1 ))
            # nota:
            #   - `r=0 ≑ n≤w`
            #   - `r⋅w+c ≑ n-w`
            # beware:
            #   - `{r,c} ∈ ℕ`
            #   - `{n,h,w} ∈ ℕ*`
            _do_notice 3 "$_i_cell_n# ($_i_cell_r,$_i_cell_c) = $_i_cell_v"
            _do_notice 6 "gen=$_i_gen_count,pos=$_i_cell_n,val=$_i_cell_v"
            if test $_i_cell_c -eq 0 ||
                test $_i_cell_n -le $_i_size1_w
            then
                __nw=0
            else # @(c-1,r-1)
                _do_notice 5 "$_i_cell_n# North-West"
                __nw=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n - _i_size1_w - 1 )) )
            fi
            if test $_i_cell_n -le $_i_size1_w
            then
                __nn=0
            else # @(c±0,r-1)
                _do_notice 5 "$_i_cell_n# due-North"
                __nn=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n - _i_size1_w )) )
            fi
            if test $_i_cell_c -eq $(( _i_size1_w - 1 )) ||
                test $_i_cell_n -le $_i_size1_w
            then
                __ne=0
            else # @(c+1,r-1)
                _do_notice 5 "$_i_cell_n# North-East"
                __ne=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n - _i_size1_w + 1 )) )
            fi
            if test $_i_cell_c -eq 0 ||
                test $_i_cell_n -le 1
            then
                __ww=0
            else # @(c-1,r±0)
                _do_notice 5 "$_i_cell_n# due-West"
                __ww=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n - 1 )) )
            fi
            if test $_i_cell_c -eq $(( _i_size1_w - 1 ))
            then
                __ee=0
            else # @(c+1,r±0)
                _do_notice 5 "$_i_cell_n# due-East"
                __ee=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n + 1 )) )
            fi
            if test $_i_cell_c -eq 0 ||
                test $_i_cell_r -eq $(( _i_size1_h - 1 ))
            then
                __sw=0
            else # @(c-1,r+1)
                _do_notice 5 "$_i_cell_n# South-West"
                __sw=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n + _i_size1_w - 1 )) )
            fi
            if test $_i_cell_r -eq $(( _i_size1_h - 1 ))
            then
                __ss=0
            else # @(c±0,r+1)
                _do_notice 5 "$_i_cell_n# South-East"
                __ss=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n + _i_size1_w )) )
            fi
            if test $_i_cell_c -eq $(( _i_size1_w - 1 )) ||
                test $_i_cell_r -eq $(( _i_size1_h - 1 ))
            then
                __se=0
            else # @(c+1,r+1)
                _do_notice 5 "$_i_cell_n# due-South"
                __se=$( echo "$_l_grid_last" |
                    cut -c $(( _i_cell_n + _i_size1_w + 1 )) )
            fi
            _i_cell_w=$(( __nw + __nn + __ne + __ww + __ee + __sw + __ss + __se ))
            if echo "$_l_cond_make" | grep -qs "$_i_cell_w"
            then
                test $_i_cell_v -eq 0 &&
                    #_do_notice 2 "birth ($_i_cell_r,$_i_cell_c): $_i_cell_w near"
                    _do_notice 2 "👶 ($_i_cell_r,$_i_cell_c)\n$__nw $__nn $__ne\n$__ww x $__ee\n$__sw $__ss $__se"
                _l_grid_temp="${_l_grid_temp}1"
            elif echo "$_l_cond_keep" | grep -qs "$_i_cell_w"
            then
                test $_i_cell_v -eq 1 &&
                    #_do_notice 2 "alive ($_i_cell_r,$_i_cell_c): $_i_cell_w near"
                    _do_notice 2 "✌ ($_i_cell_r,$_i_cell_c)\n$__nw $__nn $__ne\n$__ww $( echo $_i_cell_v | tr '01' 'OI' ) $__ee\n$__sw $__ss $__se"
                _l_grid_temp="$_l_grid_temp$_i_cell_v"
            else
                test $_i_cell_v -eq 1 &&
                    #_do_notice 2 "death ($_i_cell_r,$_i_cell_c): $_i_cell_w near"
                    _do_notice 2 "☠ ($_i_cell_r,$_i_cell_c)\n$__nw $__nn $__ne\n$__ww _ $__ee\n$__sw $__ss $__se"
                _l_grid_temp="${_l_grid_temp}0"
            fi
        done
        _i_cell_r=$(( _i_cell_r + 1 ))
    done
    _l_grid_last="$_l_grid_temp"
done
_do_mapout "$_l_grid_last" $_i_size1_w
