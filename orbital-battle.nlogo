globals [
  xdrift
  ydrift
  thrust-amount
  missile-thrust-amount
  rotation-amount
  game-score
]

breed [ships ship]
breed [planets planet]
breed [products product]
breed [missiles missile]
breed [harvesters harvester]
breed [shields shield]
breed [orbital-computers orbital-computer]
breed [courses course]
breed [autonavs autonav]



turtles-own [
  xvel
  yvel
]

courses-own [
  owner
  course-timer
]

products-own [
  product-type
  value
]

ships-own [
  player?
  fuel
  ship-level
  autonav?
  orbital-computer?
]

missiles-own [
  target
  fuel
]

harvesters-own [
  harvest-range
  owner
]

shields-own [
  owner
]

orbital-computers-own [
  owner
]

autonavs-own [
  owner
]

planets-own [
  gravity
]


to setup
  clear-all
  reset-timer

  set thrust-amount 0.0001
  set missile-thrust-amount 0.0000001
  set rotation-amount 15
  set game-score 0

  ;create the player ship
  create-ships 1 [
    set color blue
    set size 3
    set heading 0
    set player? true
    set fuel 10
    set label fuel
    set ship-level 1
    set autonav? false
    set orbital-computer? false
    setxy random-xcor random-ycor
  ]

  create-computer-ship

  ;create the planet
  create-planets number-of-planets [
    set size 3
    set shape "circle"
    set gravity 0.00000001
    ;setxy random-xcor random-ycor
  ]

  ;If multiple planets, randomize their locations
  if count planets > 1 [
    ask planets [
      setxy random-xcor random-ycor
    ]
  ]

  reset-ticks
end

to go

  let j 0

  if not any? ships with [player? = true] [stop]

  if count courses = 0 [
    move-ships
    move-products
    move-missiles
    move-harvesters
    move-shields
    move-orbital-computers
    move-autonavs

    update-scoreboard

    if ticks mod 100 = 0 [
      ask missiles [set fuel fuel - 1]

      if random 1000 = 1 [
        set j random 11 + 1
        print j
        if j <= 6 [launch-fuel]
        if j = 7 [launch-weapons]
        if j = 8 [launch-harvester]
        if j = 9 [launch-shield]
        if j = 10 [launch-orbital-computer]
        if j = 11 [launch-autonav]
        move-computer-ships
      ]

      ;check to see if all the ships have been killed off.  If so, spawn a few more
      if not any? ships with [player? = false] and random 500 = 1 [
        repeat random 2 + 1 [
          create-computer-ship
        ]
      ]

      reset-ticks
    ]
  ]

  if count courses > 0 [move-courses]

  update-scoreboard

  tick
end

to update-scoreboard

  ;score
  ask patch 49 48 [set plabel (word "SCORE: " game-score)]

  ;Autonav computer
  if any? ships with [player? = true and autonav? = true] [
    ask patch -35 48 [set plabel "AUTONAV ONLINE"]
  ]

  ;orbital computer
  if any? ships with [player? = true and orbital-computer? = true] [
    ask patch -10 48 [set plabel "ORBITAL COMPUTER READY"]
  ]

  ;weapons
  if any? ships with [player? = true and ship-level = 2] [
    ask patch 10 48 [set plabel "WEAPONS ARMED"]
  ]

end

to create-computer-ship

  ;create the computer controlled ship
  create-ships 1 [
    set size 3
    set shape "lander-level1"
    set ship-level 1
    set player? false
    set fuel 10
    set label fuel
    set autonav? false
    setxy random-xcor random-ycor
  ]

end


to move-ships
  ask ships [

    set label fuel

    set xdrift 0
    set ydrift 0

    ;first check to see if the ship has an autonav.  if not, apply the affects of the planets gravity
    if autonav? = false [
      ask planets [
        if xcor > [xcor] of myself [set xdrift xdrift + gravity]
        if xcor < [xcor] of myself [set xdrift xdrift - gravity]

        if ycor > [ycor] of myself [set ydrift ydrift + gravity]
        if ycor < [ycor] of myself [set ydrift ydrift - gravity]

      ]

      set xvel xvel + xdrift
      set yvel yvel + ydrift
    ]

    ;autonav creates the effect of slowing down after thrust
    if autonav? = true [
      if xvel > 0 [set xvel xvel - 0.000000002]
      if xvel < 0 [set xvel xvel + 0.000000002]

      if yvel > 0 [set yvel yvel - 0.000000002]
      if yvel < 0 [set yvel yvel + 0.000000002]
    ]

    setxy (xcor + xvel) (ycor + yvel)


    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]


    ;check for nabing a product
    if any? products in-radius 2 [
      let j 5

      ;gain fuel based on value of product
      if [product-type = "fuel"] of one-of products in-radius 2 [
        set fuel fuel + [value] of one-of products in-radius 2
      ]

      if [product-type = "weapons"] of one-of products in-radius 2 [
        set ship-level 2
      ]

      ;die sequence
      ask products in-radius 2 [
        repeat 5 [
          set size j
          wait 0.1
          set j j - 1
        ]
        die
      ]
    ]

    if any? harvesters in-radius 2 [
      capture-harvester self one-of harvesters in-radius 2
    ]

    if any? shields with [owner = 0] in-radius 2 [
      capture-shield self one-of shields in-radius 2
    ]

    if any? orbital-computers with [owner = 0] in-radius 2 [
      capture-orbital-computer self one-of orbital-computers in-radius 2
    ]

    if any? autonavs with [owner = 0] in-radius 2 [
      capture-autonavs self one-of autonavs in-radius 2
    ]



    ;check for death
    if player? = true and any? planets in-radius 1 [crash self]
    if player? = true and any? other ships in-radius 1 [crash self]
    if any? missiles with [target = myself] in-radius 3 [
      ask missiles in-radius 3 [die]
      crash self
    ]

    ;make sure the shape is correct based on level
    ifelse player? = true [
      if ship-level = 1 and timer > 0.3 [set shape "default"]
      if ship-level = 2 and timer > 0.3 [set shape "ship-level2"]
    ][
      if ship-level = 1 and timer > 0.3 [set shape "lander-level1"]
      if ship-level = 2 and timer > 0.3 [set shape "lander-level2"]
    ]

  ]
end


to move-products
  ask products [
    set xdrift 0
    set ydrift 0
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)

    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]

    if product-type = "fuel" [set label (word "Fuel: " value)]
    if product-type = "weapons" [set label "Weapons"]

  ]
end

to move-computer-ships

  ;check for randomness of computer players
  ask ships with [player? = false] [

    ;rotate
    if random 10 >= 5 [
      repeat random 5 + 1 [set heading heading + 15]
    ]

    ;thrust
    if random 10 >= 5 [
      repeat random 5 + 1 [
        if fuel > 0 [
          set xvel xvel + thrust-amount * dx
          set yvel yvel + thrust-amount * dy
          set fuel fuel - 1
        ]
      ]
    ]

    ;fire missile
    if ship-level > 1 and fuel >= 10 and random 10 >= 7 [
      launch-missile self
    ]


  ]

end

to move-missiles

  ask missiles [

    ;if there's computer ships, point towards them
    if any? ships with [player? = false] [
      if target != nobody [set heading towards target]
      if target = nobody [
        set target min-one-of ships with [player? = false] [distance self]
      ]

      ;check for thrusting at target
      if distance one-of ships with [player? = false] <= 20 [
        missile-thrust self
      ]
    ]

    ;check fuel and set label (or die)
    if fuel <= 0 [die]
    if fuel < 50 [set label ""]
    if fuel > 500 [set label "*"]
    if fuel > 1000 [set label "**"]
    if fuel > 1500 [set label "***"]
    if fuel > 2000 [set label "****"]

    set xdrift 0
    set ydrift 0

    ;apply the affects of the planets gravity
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)


    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]
  ]

end

to move-shields

  ask shields with [owner = 0] [
    set xdrift 0
    set ydrift 0
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)

    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]
  ]

  ask shields with [owner != 0] [
    move-to owner
    set heading [heading] of owner
  ]


end

to move-orbital-computers

  ask orbital-computers with [owner = 0] [
    set xdrift 0
    set ydrift 0
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)

    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]
  ]

end

to move-autonavs

  ask autonavs with [owner = 0] [
    set xdrift 0
    set ydrift 0
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)

    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]
  ]

end




to move-harvesters
  ask harvesters [
    set xdrift 0
    set ydrift 0
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)

    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]


    if any? products with [product-type = "fuel"] in-radius harvest-range and ([owner] of self != 0) [

      ;visual graphics of harvesters doing their thing
      ask patches in-radius harvest-range [set pcolor 49]

      ask products in-radius harvest-range [

        ;harvest fuel
        if product-type = "fuel" [
          ask [owner] of myself [
            set fuel fuel + [value] of myself
          ]
        ]



        ;show graphics
        let j 10
        repeat 5 [
          set size j
          wait 0.1
          set j j - 1
        ]
        die

      ]

      ;reset patch colors
      ask patches in-radius (harvest-range + 5) [set pcolor black]
    ]
  ]

end

to move-courses

  ask courses with [course-timer > 0] [
    set xdrift 0
    set ydrift 0
    ask planets [
      if xcor > [xcor] of myself [set xdrift xdrift + gravity]
      if xcor < [xcor] of myself [set xdrift xdrift - gravity]

      if ycor > [ycor] of myself [set ydrift ydrift + gravity]
      if ycor < [ycor] of myself [set ydrift ydrift - gravity]

    ]

    set xvel xvel + xdrift
    set yvel yvel + ydrift
    setxy (xcor + xvel) (ycor + yvel)

    ;check for edge of world
    if round(xcor) = max-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor - 1
    ]
    if round(xcor) = min-pxcor [
      set xvel 0
      set yvel 0
      set xcor xcor + 1
    ]
    if round(ycor) = max-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor - 1
    ]
    if round(ycor) = min-pycor [
      set xvel 0
      set yvel 0
      set ycor ycor + 1
    ]

    set course-timer course-timer - 1
  ]

  ;kill courses with no fuel left
  ask courses with [course-timer < 1] [die]

  ;clear drawing if no courses remain
  if count courses = 0 [clear-drawing]

end

to calculate-courses

  ifelse any? ships with [player? = true and fuel > 0 and orbital-computer? = true and count courses = 0] [

    ask ships with [player? = true] [
      set fuel fuel - 1
    ]

    ask turtles with [breed != planets] [
      ask patch-here [
        sprout-courses 1 [
          set shape "dot"
          set course-timer 200000
          set owner one-of turtles-here
          set xvel [xvel] of owner
          set yvel [yvel] of owner
          set heading [heading] of owner
          pen-down
        ]
      ]
    ]
  ][
    user-message "You need an orbital computer and at least 1 fuel to calculate courses.  Also, you cannot calculate course if you are already calculating courses."
  ]

end





to thrust
  ask ships with [player? = true and fuel > 0] [
    set xvel xvel + thrust-amount * dx
    set yvel yvel + thrust-amount * dy
    set fuel fuel - 1
    if ship-level = 1 [set shape "ship-thrusting"]
    if ship-level = 2 [set shape "ship-level2-thrusting"]
    reset-timer
  ]
end


to missile-thrust [this-missile]
  ask this-missile [
      set xvel xvel + missile-thrust-amount * dx
      set yvel yvel + missile-thrust-amount * dy
  ]
end


to rotate-clockwise
  ask ships with [player? = true] [
    set heading heading + rotation-amount
  ]
end

to rotate-counterclockwise
  ask ships with [player? = true] [
    set heading heading - rotation-amount
  ]
end




to launch-orbital-computer

  if count orbital-computers with [owner = 0] <= 5 [
    ask one-of planets [
      ask patch-here [
        sprout-orbital-computers 1 [
          set xvel xvel + (random-float 0.001 + 0.0002) * dx
          set yvel yvel + (random-float 0.001 + 0.0002) * dy
          set heading random 360 + 1
          set shape "orbital-computer"
          set label "Orbital Computer"
          set size 4
          set color grey
          set owner 0
        ]
      ]
    ]
  ]

end

to launch-autonav

  if count autonavs with [owner = 0] = 0 [
    ask one-of planets [
      ask patch-here [
        sprout-autonavs 1 [
          set xvel xvel + (random-float 0.001 + 0.0002) * dx
          set yvel yvel + (random-float 0.001 + 0.0002) * dy
          set heading random 360 + 1
          set shape "target"
          set label "AutoNav"
          set size 4
          set color grey
          set owner 0
        ]
      ]
    ]
  ]

end



to launch-shield

  if count shields with [owner = 0] <= 5 [
    ask one-of planets [
      ask patch-here [
        sprout-shields 1 [
          set xvel xvel + (random-float 0.001 + 0.0002) * dx
          set yvel yvel + (random-float 0.001 + 0.0002) * dy
          set heading random 360 + 1
          set shape "shield"
          set label "Shield"
          set size 4
          set color grey
          set owner 0
        ]
      ]
    ]
  ]


end


to launch-harvester

  if count harvesters <= 5 [
    ask one-of planets [
      ask patch-here [
        sprout-harvesters 1 [
          set xvel xvel + (random-float 0.001 + 0.0002) * dx
          set yvel yvel + (random-float 0.001 + 0.0002) * dy
          set heading random 360 + 1
          set shape "factory"
          set size 3
          set color grey
          set harvest-range random 8 + 3
          set owner 0
          set label (word "Range: " harvest-range)
        ]
      ]
    ]
  ]

end


to launch-weapons

  if count products <= 10 [
    ask one-of planets [
      ask patch-here [
        sprout-products 1 [
          set xvel xvel + (random-float 0.001 + 0.0002) * dx
          set yvel yvel + (random-float 0.001 + 0.0002) * dy
          set shape "dart"
          set size 3
          set color grey
          set product-type "weapons"
          set heading random 360 + 1
          set label "Weapons"
        ]
      ]
    ]
  ]

end


to launch-fuel

  if count products <= 10 [
    ask one-of planets [
      ask patch-here [
        sprout-products 1 [
          set xvel xvel + (random-float 0.001 + 0.0002) * dx
          set yvel yvel + (random-float 0.001 + 0.0002) * dy

          ;launch a random product
          let launched-product random 4 + 1
          if launched-product = 1 [
            set shape "cloud"
            set size 3
            set color blue
            set product-type "fuel"
            set heading random 360 + 1
            set value 5
          ]

          if launched-product = 2 [
            set shape "cloud"
            set size 3
            set color green
            set product-type "fuel"
            set heading random 360 + 1
            set value 10
          ]

          if launched-product = 3 [
            set shape "cloud"
            set size 3
            set color yellow
            set product-type "fuel"
            set heading random 360 + 1
            set value 15
          ]

          if launched-product = 3 [
            set shape "cloud"
            set size 3
            set color orange
            set product-type "fuel"
            set heading random 360 + 1
            set value 30
          ]

          if launched-product = 4 [
            set shape "cloud"
            set size 3
            set color red
            set product-type "fuel"
            set heading random 360 + 1
            set value 50
          ]

         set label value

        ]
      ]
    ]
  ]

end

to launch-missile [ship-firing-missile]

  carefully [
    ask ship-firing-missile [
      ifelse fuel >= 10 and ship-level > 1 [
        set fuel fuel - 10
        ask patch-here [
          sprout-missiles 1 [
            set fuel 2500
            set xvel xvel + (random-float 0.001 + 0.0001) * dx
            set yvel yvel + (random-float 0.001 + 0.0001) * dy
            set shape "dart"
            set size 3
            set color [color] of ship-firing-missile
            set target one-of ships with [who != [who] of ship-firing-missile]
          ]
        ]
      ] [
        user-message "You need weapons on your ship and at least 10 fuel to launch a missile."
      ]
    ]
  ][]

end

to capture-orbital-computer [ship-capturing-orbital-computer orbital-computer-being-captured]

  if not any? orbital-computers with [owner = ship-capturing-orbital-computer] [
    ask orbital-computer-being-captured [die]
    ask ship-capturing-orbital-computer [set orbital-computer? true]
    if [player? = true] of ship-capturing-orbital-computer [
      user-message "You may now calculate courses using your new orbital computer.  Each calculation costs 1 fuel."
    ]
  ]

end

to capture-autonavs [ship-capturing-autonavs autonavs-being-captured]

  if not any? autonavs with [owner = ship-capturing-autonavs] [
    ask autonavs-being-captured [die]
    ask ship-capturing-autonavs [set autonav? true]
    if [player? = true] of ship-capturing-autonavs [
      user-message "Your AutoNav will now hold you stable versus planetary gravity."
    ]
  ]

end


to capture-shield [ship-capturing-shield shield-being-captured]

  if not any? shields with [owner = ship-capturing-shield] [
    ask shield-being-captured [
      set color [color] of ship-capturing-shield
      set owner ship-capturing-shield
      set label ""
    ]
  ]

end



to capture-harvester [ship-capturing-harvester harvester-being-captured]

  carefully [
    if [owner] of harvester-being-captured != ship-capturing-harvester [
      ask ship-capturing-harvester [

        if fuel >= 25 [
          set fuel fuel - 25

          ask harvester-being-captured [
            set color [color] of ship-capturing-harvester
            set owner ship-capturing-harvester
          ]

          if [player? = true] of ship-capturing-harvester [
            user-message "You have captured this harvester!  Capturing harvesters cost 25 fuel."
          ]

          ask ship-capturing-harvester [fd 2]

        ]

      ]
    ]
  ][]

end






to game-over [this-ship]
  let j 10

  ask this-ship [
    repeat 5 [
      set size j
      wait 0.1
      set j j - 1
    ]
    if player? = false [
      set game-score game-score + 1
      ask harvesters with [owner = this-ship] [
        set owner 0
        set color grey
      ]
    ]
    die
  ]
end

to crash [this-ship]
  let j 5

  ask this-ship [
    ifelse any? shields with [owner = this-ship] [
      repeat 5 [
        set size j
        wait 0.1
        set j j - 1
      ]
      set size 3
      ask shields with [owner = this-ship] [die]
      fd 3
    ][game-over self]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
8
10
771
774
-1
-1
7.48
1
12
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
848
153
913
186
Thruster
thrust
NIL
1
T
OBSERVER
NIL
5
NIL
NIL
1

BUTTON
821
20
884
53
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
884
20
947
53
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

BUTTON
913
153
968
186
Right
rotate-clockwise
NIL
1
T
OBSERVER
NIL
6
NIL
NIL
1

BUTTON
794
153
849
186
Left
rotate-counterclockwise
NIL
1
T
OBSERVER
NIL
4
NIL
NIL
1

BUTTON
794
210
925
243
Fire Missile!
launch-missile one-of ships with [player? = true]
NIL
1
T
OBSERVER
NIL
F
NIL
NIL
1

SLIDER
823
63
1013
96
number-of-planets
number-of-planets
1
5
1.0
1
1
planet
HORIZONTAL

BUTTON
794
242
925
275
Calculate Courses
calculate-courses
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

cloud
false
0
Circle -7500403 true true 13 118 94
Circle -7500403 true true 86 101 127
Circle -7500403 true true 51 51 108
Circle -7500403 true true 118 43 95
Circle -7500403 true true 158 68 134

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

dart
true
0
Polygon -7500403 true true 135 90 150 285 165 90
Polygon -7500403 true true 135 285 105 255 105 240 120 210 135 180 150 165 165 180 180 210 195 240 195 255 165 285
Rectangle -1184463 true false 135 45 165 90
Line -16777216 false 150 285 150 180
Polygon -16777216 true false 150 45 135 45 146 35 150 0 155 35 165 45
Line -16777216 false 135 75 165 75
Line -16777216 false 135 60 165 60

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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

lander-level1
true
0
Polygon -7500403 true true 135 205 120 235 180 235 165 205
Polygon -16777216 false false 135 205 120 235 180 235 165 205
Line -7500403 true 75 30 195 30
Polygon -7500403 true true 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135
Polygon -16777216 false false 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135
Polygon -7500403 true true 75 75 105 45 195 45 225 75 225 135 195 165 105 165 75 135
Polygon -16777216 false false 75 75 105 45 195 45 225 75 225 120 225 135 195 165 105 165 75 135
Polygon -16777216 true false 217 90 210 75 180 60 180 90
Polygon -16777216 true false 83 90 90 75 120 60 120 90
Polygon -16777216 false false 135 165 120 135 135 75 150 60 165 75 180 135 165 165
Circle -7500403 true true 120 15 30
Circle -16777216 false false 120 15 30
Line -7500403 true 150 0 150 45
Polygon -1184463 true false 90 165 105 210 195 210 210 165
Line -1184463 false 210 165 245 239
Line -1184463 false 237 221 194 207
Rectangle -1184463 true false 221 245 261 238
Line -1184463 false 90 165 55 239
Line -1184463 false 63 221 106 207
Rectangle -1184463 true false 39 245 79 238
Polygon -16777216 false false 90 165 105 210 195 210 210 165
Rectangle -16777216 false false 221 237 262 245
Rectangle -16777216 false false 38 237 79 245

lander-level2
true
0
Polygon -7500403 true true 135 205 120 235 180 235 165 205
Polygon -16777216 false false 135 205 120 235 180 235 165 205
Line -7500403 true 75 30 195 30
Polygon -7500403 true true 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135
Polygon -16777216 false false 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135
Polygon -7500403 true true 75 75 105 45 195 45 225 75 225 135 195 165 105 165 75 135
Polygon -16777216 false false 75 75 105 45 195 45 225 75 225 120 225 135 195 165 105 165 75 135
Polygon -16777216 true false 217 90 210 75 180 60 180 90
Polygon -16777216 true false 83 90 90 75 120 60 120 90
Polygon -16777216 false false 135 165 120 135 135 75 150 60 165 75 180 135 165 165
Circle -7500403 true true 120 15 30
Circle -16777216 false false 120 15 30
Line -7500403 true 150 0 150 45
Polygon -1184463 true false 90 165 105 210 195 210 210 165
Line -1184463 false 210 165 245 239
Line -1184463 false 237 221 194 207
Rectangle -1184463 true false 221 245 261 238
Line -1184463 false 90 165 55 239
Line -1184463 false 63 221 106 207
Rectangle -1184463 true false 39 245 79 238
Polygon -16777216 false false 90 165 105 210 195 210 210 165
Rectangle -16777216 false false 221 237 262 245
Rectangle -16777216 false false 38 237 79 245
Rectangle -2674135 true false 45 60 75 165
Rectangle -2674135 true false 225 60 255 165
Line -2674135 false 60 30 60 60
Line -2674135 false 240 30 240 75

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

orbital-computer
true
0
Circle -7500403 true true 116 11 67
Circle -7500403 true true 26 176 67
Circle -7500403 true true 206 176 67
Circle -7500403 false true 45 45 210

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

shield
true
0
Polygon -1184463 true false 30 150 105 15 195 15 285 150 255 150 180 30 120 30 60 150

ship-level2
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250
Line -2674135 false 90 135 90 30
Rectangle -2674135 true false 75 75 105 150
Rectangle -2674135 true false 195 75 225 150
Line -2674135 false 210 30 210 90

ship-level2-thrusting
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250
Line -2674135 false 90 135 90 30
Rectangle -2674135 true false 75 75 105 150
Rectangle -2674135 true false 195 75 225 150
Line -2674135 false 210 30 210 90
Line -1 false 75 240 75 270
Line -1 false 105 240 105 285
Line -1 false 135 225 135 285
Line -1 false 165 225 165 285
Line -1 false 195 240 195 285
Line -1 false 225 240 225 270

ship-thrusting
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250
Line -1 false 90 240 90 270
Line -1 false 210 240 210 270
Line -1 false 120 225 120 285
Line -1 false 180 225 180 285
Line -1 false 150 210 150 300

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
NetLogo 6.3.0-beta1
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
