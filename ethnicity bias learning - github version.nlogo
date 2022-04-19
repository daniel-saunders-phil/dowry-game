turtles-own [
  strategy
  learning-strategy
  marker
  payoff]

globals [
  num-turtles]

to setup

  ; Builds the initial population
  ; It divides the screen in half, marking the top half
  ; as one group and the bottom half as another.
  ; Each group has a characteristic strategy
  ; and marker.

  clear-all
  ask patches with [pycor > max-pycor / 2] [sprout 1 [
    set shape "circle"
    ifelse conditional_strategies? = True [

      ; if players are using conditional strategies
      ; then strategies take the form of a list
      ; where the first item is the in-group strategy
      ; and the second item is the out-group strategy

      set strategy list 0 (random 2)][
      set strategy 0]
    set marker 0
    set learning-strategy 0
    recolor]]

  ask patches with [pycor <= max-pycor / 2] [sprout 1 [
    set shape "square"
    ifelse conditional_strategies? = True [
      set strategy list 1 (random 2)][
      set strategy 1]
    set marker 1
    set learning-strategy 0
    recolor]]

  ; Sets the global variable for easy reference elsewhere.

  set num-turtles count turtles

  ; Has a parameter-controlled proportion of player adopt
  ; Ethnicity-biased social learning.

  ask n-of (num-turtles * initial_proportion_ethnic_learning) turtles [
    set learning-strategy 1]

  reset-ticks
end

to go

  ; Every player performs all these commands every round

  ask turtles [
    set payoff 0
    repeat plays_per_learn [play] ; plays_per_learn represents *n* from the manuscript
    learn
    learn-learning-strategy
    mutate-strategy
    mutate-learning-strategy
    recolor]

  tick
end

; ================== interaction ===================

to play

  ; a tree to decide which version of the play
  ; algorithm to employ.
  ; When players use conditional strategies
  ; or when the population has spatial structure
  ; slightly different algorithms are necessary

  ifelse spatial? = true [
    ifelse conditional_strategies? = True [
      play-conditional-spatial][
      play-unconditional-spatial]][
    ifelse conditional_strategies? = True [
      play-conditional][
      play-unconditional]]

end

to play-unconditional

  ; First, determine whether the partner is a random other player
  ; or a member of one's own ethnic group (identified by a marker)
  ; this decision is made with a probability controlled by a parameter.

  ifelse random-float 1 < random-pairing [

    ;__the random pairing case__

    let partner one-of other turtles
    let s2 [strategy] of partner

    ; if the players have the same strategy
    ; they get a payoff.
    ; Otherwise they get nothing.

    ifelse s2 = strategy [
      set payoff payoff + 1][
      set payoff payoff]

  ][

    ;__the in-group pairing case__

    let my-marker marker
    let partner one-of other turtles with [marker = my-marker]
    if partner != nobody [
      let s2 [strategy] of partner
      ifelse s2 = strategy [
       set payoff payoff + 1][
       set payoff payoff]]]

end


to play-conditional

  ; this code is largely the same,
  ; comments will flag differences.

  ifelse random-float 1 < random-pairing [

    let my-marker marker
    let partner one-of other turtles

    ; payoff determination is slightly
    ; more complex when dealing with
    ; conditional strategies. I have to
    ; extract the right action from the list
    ; and then execute the code as normal.

    ifelse my-marker = [marker] of partner [


      let s1-play item 0 strategy ; item 0 is the in-group strategy
      let s2 [strategy] of partner
      let s2-play item 0 s2

      ifelse s2-play = s1-play [
        set payoff payoff + 1][
        set payoff payoff]]

    [
      ;__out-group interaction__

      let s1-play item 1 strategy ; item 1 is the out-group strategy
      let s1-save item 0 strategy
      let s2 [strategy] of partner
      let s2-play item 1 s2

      ifelse s2-play = s1-play [
        set payoff payoff + 1][
        set payoff payoff]]

  ][
    ;__the in-group pairing case__

    let my-marker marker
    let partner one-of other turtles with [marker = my-marker]
    if partner != nobody [

      let s1-play item 0 strategy
      let s2 [strategy] of partner
      let s2-play item 0 s2

      ifelse s2-play = s1-play [
        set payoff payoff + 1][
        set payoff payoff]]]

end

to play-unconditional-spatial

  ifelse random-float 1 < random-pairing [

    ; possible-partners are the neighbors

    let possible-partners turtles-on neighbors
    let partner one-of possible-partners
    let s2 [strategy] of partner

    ifelse s2 = strategy [
      set payoff payoff + 1][
      set payoff payoff]

  ][

    let my-marker marker
    let possible-partners turtles-on neighbors
    let partner one-of possible-partners with [marker = my-marker]
    if partner != nobody [
      let s2 [strategy] of partner
      ifelse s2 = strategy [
       set payoff payoff + 1][
       set payoff payoff]]]

end


to play-conditional-spatial
  ifelse random-float 1 < random-pairing [

    let my-marker marker
    let possible-partners turtles-on neighbors
    let partner one-of possible-partners

    ifelse my-marker = [marker] of partner [


      let s1-play item 0 strategy ; here
      let s2 [strategy] of partner
      let s2-play item 0 s2

      ifelse s2-play = s1-play [
        set payoff payoff + 1][
        set payoff payoff]]

    [

      let s1-play item 1 strategy
      let s1-save item 0 strategy
      let s2 [strategy] of partner
      let s2-play item 1 s2

      ifelse s2-play = s1-play [
        set payoff payoff + 1][
        set payoff payoff]]

  ][

    let my-marker marker
    let possible-partners turtles-on neighbors
    let partner one-of possible-partners with [marker = my-marker]
    if partner != nobody [

      let s1-play item 0 strategy
      let s2 [strategy] of partner
      let s2-play item 0 s2

      ifelse s2-play = s1-play [
        set payoff payoff + 1][
        set payoff payoff]]]

end

; ======================= learning algos =======================

to learn
  ifelse spatial? = True [
    learn-spatial][
    learn-nonspatial]

end

to learn-nonspatial

  ; First, the player decided whether they will
  ; learn from a random partner or learn from someone
  ; from their ethnic group. This decision is made
  ; based on their learning strategy. 0 for random partner
  ; 1 for in-group.

  if learning-strategy = 0 [

    ; identify the partner and their payoff

    let partner one-of other turtles
    let training-data [payoff] of partner

    ; copy their strategy with probability proportional to
    ; the difference in payoffs between players.

    if random-float 1 < (training-data - payoff) / plays_per_learn [
      set strategy ([strategy] of partner)]]

  if learning-strategy = 1 [
    let m marker
    let partner one-of other turtles with [marker = m]

    ; checking if your partner is nobody prevents
    ; errors. Sometimes you are the only member of the ethnic
    ; group there is no other partner to pick.

    if partner != nobody [
      let training-data [payoff] of partner

      if random-float 1 < (training-data - payoff) / plays_per_learn [
        set strategy ([strategy] of partner)]]]

end

to learn-spatial

  ; same code as above but we employ the same
  ; possible partners trick

  if learning-strategy = 0 [

    let partner one-of other turtles-on neighbors
    let training-data [payoff] of partner

    if random-float 1 < (training-data - payoff) / plays_per_learn [
      set strategy ([strategy] of partner)]]

  if learning-strategy = 1 [
    let m marker
    let possible-partners turtles-on neighbors
    let partner one-of possible-partners  with [marker = m]

    if partner != nobody [
      let training-data [payoff] of partner

      if random-float 1 < (training-data - payoff) / plays_per_learn [
        set strategy ([strategy] of partner)]]]

end

;================ learning strategy algos ===================

to learn-learning-strategy
  ifelse spatial? = True [
    learn-learning-strategy-spatial][
    learn-learning-strategy-nonspatial]
end


to learn-learning-strategy-nonspatial

  ; pick a random partner

  ;let m marker
  let teacher one-of other turtles ; with [marker = m] ; I left this piece of commented out code.
                                                       ; so you can easily toggle on marker-based second order learning.
                                                       ; It seems to have no effect on the results.
  if teacher != nobody [
    let ls [learning-strategy] of teacher
    let data [payoff] of teacher

    ; copy their learning strategy if they recieved
    ; a larger payoff.

    if random-float 1 < (data - payoff) / plays_per_learn [
      set learning-strategy ls]]

end

to learn-learning-strategy-spatial

  ; again, I define possible-partners as the neighbors
  ; and the rest of the code is the same

  let possible-partners turtles-on neighbors
  let teacher one-of possible-partners
  if teacher != nobody [
    let ls [learning-strategy] of teacher
    let data [payoff] of teacher

    if random-float 1 < (data - payoff) / plays_per_learn [
      set learning-strategy ls]]

end

; ====================== disruptors ===================

to mutate-learning-strategy

  ; a mutation rate for learning strategies

  if random-float 1 < mr_learning_style [
    set learning-strategy random 2]
end

to mutate-strategy

  ; a mutation rate for behavioral strategies

  if random-float 1 < mr_strategy [
    ifelse conditional_strategies? = True [
      set strategy list random 2 random 2][
      set strategy random 2]]
end

;===================== aesthetics =====================

to recolor

  ; implements the color scheme
  ; behavior 0 is a deep red
  ; behavior 1 is a deep blue

  if strategy = 0 [set color 26]
  if strategy = 1 [set color 94]

  ; a more complex color scheme for conditional strategies

  if strategy = [0 0] [set color 94]
  if strategy = [1 1] [set color 86]
  if strategy = [1 0] [set color 15]
  if strategy = [0 1] [set color 26]

end

;=================== reporter ========================
; reporters to measure the two possible outcomes
; either the two groups assimilate
; or ethnicity-biased social learning spreads.

to-report collapse?
  report num-turtles = count turtles with [strategy = 0] or num-turtles = count turtles with [strategy = 1] or num-turtles = count turtles with [learning-strategy = 0]
end

to-report success?
  report num-turtles = count turtles with [learning-strategy = 1]
end
@#$#@#$#@
GRAPHICS-WINDOW
203
10
563
154
-1
-1
13.54
1
10
1
1
1
0
1
1
1
0
25
0
9
1
1
1
ticks
30.0

SLIDER
22
11
194
44
random-pairing
random-pairing
0
1
0.49
0.01
1
NIL
HORIZONTAL

BUTTON
22
282
85
315
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
88
282
151
315
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
21
84
193
117
mr_strategy
mr_strategy
0
1
0.0
0.001
1
NIL
HORIZONTAL

PLOT
569
10
788
154
average payoff
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-y-range 0 1" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (sum [payoff] of turtles) / num-turtles\n"

PLOT
569
162
790
332
strategy frequencies
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"behavior 0" 1.0 0 -13345367 true "" "plot count turtles with [strategy = 0] / num-turtles"
"behavior 1" 1.0 0 -2674135 true "" "plot count turtles with [strategy = 1] / num-turtles"
"[0 0]" 1.0 0 -10649926 true "" "plot count turtles with [strategy = [0 0]] / num-turtles"
"[1 0]" 1.0 0 -2674135 true "" "plot count turtles with [strategy = [1 0]] / num-turtles"
"[0 1]" 1.0 0 -817084 true "" "plot count turtles with [strategy = [0 1]] / num-turtles"
"[1 1]" 1.0 0 -8275240 true "" "plot count turtles with [strategy = [1 1]] / num-turtles"

PLOT
209
161
556
331
social learning
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"ethnic learning" 1.0 0 -12087248 true "" "plot count turtles with [learning-strategy = 1] / num-turtles"
"general learning" 1.0 0 -14070903 true "" "plot count turtles with [learning-strategy = 0] / num-turtles"

SLIDER
21
121
193
154
mr_learning_style
mr_learning_style
0
1
0.0
.001
1
NIL
HORIZONTAL

SLIDER
21
48
194
81
initial_proportion_ethnic_learning
initial_proportion_ethnic_learning
0
1
0.96
.01
1
NIL
HORIZONTAL

SLIDER
21
157
193
190
plays_per_learn
plays_per_learn
0
10
9.0
1
1
NIL
HORIZONTAL

SWITCH
21
194
194
227
conditional_strategies?
conditional_strategies?
0
1
-1000

SWITCH
22
232
125
265
spatial?
spatial?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model studies the conditions under which ethnicity biased social learning is adaptive. --- underdevelopment.

## HOW TO USE IT

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
