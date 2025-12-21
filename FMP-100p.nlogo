;The Farm Management Platform (FMP) Version 1.0.0 (August 2025)
;Compiled by Anapat Meemungkung on Netlogo 6.2.0, Modified from FEWCalc by Jirapat Phetheet (2021)
;Adjustable parameters are marked as "adjustable"

extensions [ csv bitmap ]

;breed [ farmers farmer ]

;farmers-own [ food-security energy-costs-farmer water-availability ghg-awareness management-practice ]

globals
[
  zero-line total-area crop-area area-multiplier radius-of-%area
  storage-availability gw-availability total-water-available
  count-solar-lifespan_SW count-solar-lifespan-cost_SW count-solar-lifespan_GW count-solar-lifespan-cost_GW count-fossil-lifespan count-elec-lifespan ft
  sol_pump_lifespan_SW sol_pump_lifespan_GW
  background water-bg sw-patches gw-patches storage-patches
  precip_base-dry precip_base-wet precip_45-dry precip_45-wet precip_85-dry precip_85-wet
  rice-base-dry rice-base-wet rice-45-dry rice-45-wet rice-85-dry rice-85-wet
  rice-sum_repeat1 rice-sum_repeat2 rice-sum_451 rice-sum_452 rice-sum_851 rice-sum_852
  rice-yield_1 rice-irrig_1 rice-yield_1A rice-irrig_1A rice-yield_1U rice-irrig_1U rice-yield_1UA rice-irrig_1UA
  rice-yield_2 rice-irrig_2 rice-yield_2A rice-irrig_2A rice-yield_2U rice-irrig_2U rice-yield_2UA rice-irrig_2UA
  rice-yield_451 rice-irrig_451 rice-yield_451A rice-irrig_451A rice-yield_451U rice-irrig_451U rice-yield_451UA rice-irrig_451UA
  rice-yield_452 rice-irrig_452 rice-yield_452A rice-irrig_452A rice-yield_452U rice-irrig_452U rice-yield_452UA rice-irrig_452UA
  rice-yield_851 rice-irrig_851 rice-yield_851A rice-irrig_851A rice-yield_851U rice-irrig_851U rice-yield_851UA rice-irrig_851UA
  rice-yield_852 rice-irrig_852 rice-yield_852A rice-irrig_852A rice-yield_852U rice-irrig_852U rice-yield_852UA rice-irrig_852UA
  rice-price rice-costs energy-costs acc-energy-costs
  rice-tot-yield rice-tot-income rice-net-income rice-expenses
  rice-irreq total-irreq total-water-use waterlevel
  solar-production-temp_SW solar-production_SW solar-cost-temp_SW solar-cost_SW fossil-cost-temp fossil-cost acc-solar-cost_SW acc-fossil-cost
  solar-production-temp_GW solar-production_GW solar-cost-temp_GW solar-cost_GW elec-cost-temp elec-cost acc-solar-cost_GW acc-elec-cost
  emission-co2 burn-emission-co2 burn-emission-ch4 area-burnt urea-emission-co2 rice-emission-ch4 efactor-rice sfw sfp sfo cfoa roa rice-emission-ch4-single
]

to setup

  ca
  import-data
  set zero-line 0                                                                          ; Zero line in output plots

  ; agriculture setup ;;;;;;;;;;
  if unit_area = "Hectare"
  [ set total-area rice_area                                                               ; Hectare is used as primary unit area for calculations
    set rice-costs 22470 ]                                                                 ; Adjustable, Costs for rice production (except energy costs) is 22470 THB/ha or 23140 THB/ha with energy costs (OAE, 2019)
  if unit_area = "Rai"
  [ set total-area (rice_area / 6.25)                                                      ; 1 Hectare = 6.25 Rai
    set rice-costs 22470 / 6.25 ]                                                          ; Adjustable, Costs for rice production (except energy costs) per Rai
  set rice-price 7.94
  ;ifelse Location = "Upland" and Crop_2_seasons = False                                   ; Rice variety for upland, in-season is KDML105, Rice variety for other cases is RD rice
  ;[ set rice-price 13.0 ]                                                                 ; Adjustable, 2008-24 Avg rice market price for KDML105 is 13.0 THB/kg (OAE, 2024)
  ;[ set rice-price 8.8 ]                                                                  ; Adjustable, 2008-24 Avg rice market price for RD rice is 8.8 THB/kg (OAE, 2024)
  set emission-co2 0
  set rice-emission-ch4 0
  if Management = "As_usual"
  [ set rice_water_regime "Irrigated, Continuously flooded" ]
  if Management = "AWD"
  [ set rice_water_regime "Irrigated, Multiple drainage" ]

  ; water setup ;;;;;;;;;;
  ifelse use_surfacewater? = true
  [ ifelse unlimited_storage? = true
    [ set storage-availability 1000000 ]
    [ set storage-availability Storage_capacity ]
  ]
  [ set storage-availability 0 ]

  ifelse use_groundwater? = true
  [ set gw-availability (groundwater_yield * 24 * cultivation_period) ]                    ; calculate maximum gw availability in m3 per rice season (m3/hr > m3/day > m3/season)
  [ set gw-availability 0 ]
  set total-water-available (storage-availability + gw-availability)
  if Groundwater_pump_rate >= Groundwater_yield
  [ set Groundwater_pump_rate Groundwater_yield ]

  set waterlevel 0

  ; energy setup ;;;;;;;;;;
  ; solar energy (surface water and storage) ;
  set count-solar-lifespan_SW 1
  set count-solar-lifespan-cost_SW 1
  ifelse Use_solar_energy_for_SW? = True
  [ set solar-cost_SW Sol_maintain_cost_SW
    set acc-solar-cost_SW (Sol_install_cost_SW + Sol_pump_install_cost_SW) ]
  [ set solar-cost_SW 0
    set acc-solar-cost_SW 0 ]
  set solar-production_SW (sol_capacity_SW * sun_hours_SW * 365 / 1000000)
  set sol_pump_lifespan_SW (sol_lifespan_SW / 2)

  ; solar energy (groundwater) ;
  set count-solar-lifespan_GW 1
  set count-solar-lifespan-cost_GW 1
  ifelse Use_solar_energy_for_GW? = True
  [ set solar-cost_GW Sol_maintain_cost_SW
    set acc-solar-cost_GW (Sol_install_cost_GW + Sol_pump_install_cost_GW) ]
  [ set solar-cost_GW 0
    set acc-solar-cost_GW 0 ]
  set solar-production_GW (sol_capacity_GW * sun_hours_GW * 365 / 1000000)
  set sol_pump_lifespan_GW (sol_lifespan_GW / 2)

  ; fossil fuels (surface water and storage) ;
  set count-fossil-lifespan 1
  ifelse Use_fossil_fuels? = True
  [ set fossil-cost (Fuel_price * Fuel_consumption) + Fuel_maintain_cost
    set acc-fossil-cost Fuelpump_cost ]
  [ set fossil-cost 0
    set acc-fossil-cost 0 ]

  ; electricity (groundwater) ;
  set count-elec-lifespan 1
  ifelse Use_electricity? = True
  [ set elec-cost 0
    set acc-elec-cost Elec_install_cost_GW ]
  [ set elec-cost 0
    set acc-elec-cost 0 ]

  set acc-energy-costs (acc-solar-cost_SW + acc-solar-cost_GW + acc-fossil-cost + acc-elec-cost)
  set energy-costs (solar-cost_SW + solar-cost_GW + fossil-cost + elec-cost)
  set rice-expenses (rice-costs + energy-costs)

  ; display ;;;;;;;;;;
  ask patch -80 95 [set plabel "World"]

  ; crop background ;
  set background bitmap:import "Background.jpg"
  bitmap:copy-to-pcolors background false

  ;------------------------------------------------------------;

  ; water bar ;
  ;set water-bg patches with [pxcor > 62]
  ;ask water-bg [set pcolor black]
  ;ask patch 99.2 95 [set plabel "Water Level"]
  ;set sw-patches patches with [pxcor > 64 and pxcor < 75]
  ;ask sw-patches [set pcolor 106]
  ;ask patch 74.5 -96 [set plabel "SW"]
  ;set gw-patches patches with [pxcor > 76 and pxcor < 87]
  ;ask gw-patches [set pcolor 105]
  ;ask patch 87 -96 [set plabel "GW"]
  ;set storage-patches patches with [pxcor > 88 and pxcor < 99]
  ;ask storage-patches [set pcolor 5]
  ;ask patch 97 -96 [set plabel "ST"]

  ;------------------------------------------------------------;

  ; food icons ;
  set crop-area []
  set crop-area lput total-area crop-area

  set radius-of-%area []
  set area-multiplier 3000
  let m 0
  let n 0
  foreach crop-area [ x ->
    set radius-of-%area lput sqrt ((x / (sum crop-area) * area-multiplier) / pi) radius-of-%area
  ]

  if total-area > 0 [
  ask patch -20 36 [ask patches in-radius (item 0 radius-of-%area) [set pcolor 44]]
  import-drawing "Rice.png"
  ask patch -14 13 [set plabel "Rice"]]

  ;------------------------------------------------------------;

  ; water and energy icons ;
  ask patch -66 -71 [set plabel "Water use"]
  ask patch 33 -71 [set plabel "Energy use"]

  if Use_surfacewater? = True [import-drawing "River.png"]
  if Use_groundwater? = True [import-drawing "Well.png"]
  ; if Use_storage? = True [import-drawing "Pond.png"]
  if Use_fossil_fuels? = True [import-drawing "Fossilfuels.png"]
  if Use_electricity? = True [import-drawing "Electricity.png"]
  if Use_solar_energy_for_SW? = True [import-drawing "Solarcells.png"]
  if Use_solar_energy_for_GW? = True [import-drawing "Solarcells.png"]

  reset-ticks

end

to go

  if ticks = simulation_period [stop]
  check-area
  future-processes
  ;update-farmer-behavior
  update-environment
  tick

end

to restore-default

  set simulation_period 100
  set future_climate "RCP4.5"
  set management "As_usual"
  set crop_seasons "1"
  set unit_area "Hectare"
  set rice_area 1

  set use_surfacewater? true
  set unlimited_storage? true
  set use_groundwater? false
  set surfacewater_pump_rate 25
  set surfacewater_pump_hours 4
  set surfacewater_pump_day 30
  set storage_pump_rate 25
  set storage_pump_hours 4
  set storage_pump_day 30
  set storage_capacity 100
  set groundwater_pump_rate 5
  set groundwater_pump_hours 4
  set groundwater_pump_day 30
  set groundwater_yield 5

  set #users_SW 1
  set sol_capacity_SW 2400
  set sun_hours_SW 4.4
  set sol_lifespan_SW 25
  set degradation_SW 0.5
  set sol_install_cost_SW 12000
  set sol_maintain_cost_SW 500
  set use_solar_energy_for_SW? true
  set use_fossil_fuels? true
  set fuelpump_lifespan 25
  set fuelpump_cost 10000
  set fuel_maintain_cost 500
  set fuel_price 30
  set fuel_consumption 50

  set #users_GW 1
  set sol_capacity_GW 2400
  set sun_hours_GW 4.4
  set sol_lifespan_GW 25
  set degradation_GW 0.5
  set sol_install_cost_GW 12000
  ;set sol_maintain_cost_GW 1000
  set use_solar_energy_for_GW? true
  set use_electricity? true
  set Elec_pump_watt_GW 1100
  set Elec_pump_lifespan 25
  set Elec_install_cost_GW 12000

  set cultivation_period 110
  set Rice_water_regime "Irrigated, Continuously flooded"
  set Rice_pre-season_water_regime "<180 days non-flooded"
  set Organic_amendment "Not applied"
  set Burning_area 0
  set Applied_urea_fertilizer 0
  set Organic_amendment_weight 0

end

to import-data                                                                             ; Create a number of lists to store values from csv files

  ; import climate data ;;;;;;;;;;
  set precip_base-dry []                                                                   ; A list for base precipitation data (dry seasons)
  set precip_base-wet []                                                                   ; A list for base precipitation data (wet seasons)
  set precip_45-dry []                                                                     ; A list for RCP4.5 precipitation data (dry seasons)
  set precip_45-wet []                                                                     ; A list for RCP4.5 precipitation data (wet seasons)
  set precip_85-dry []                                                                     ; A list for RCP8.5 precipitation data (dry seasons)
  set precip_85-wet []                                                                     ; A list for RCP8.5 precipitation data (wet seasons)

  ; import crop data ;;;;;;;;;;
  set rice-base-dry []                                                                     ; All rice data including headings of the table (base, dry seasons)
  set rice-base-wet []                                                                     ; All rice data including headings of the table (base, wet seasons)
  set rice-45-dry []                                                                       ; All rice data including headings of the table (RCP45, dry seasons)
  set rice-45-wet []                                                                       ; All rice data including headings of the table (RCP45, wet seasons)
  set rice-85-dry []                                                                       ; All rice data including headings of the table (RCP85, dry seasons)
  set rice-85-wet []                                                                       ; All rice data including headings of the table (RCP85, wet seasons)

  set rice-sum_repeat1 []                                                                  ; Repeat historical (dry seasons)
  set rice-sum_repeat2 []                                                                  ; Repeat historical (wet seasons)
  set rice-sum_451 []                                                                      ; RCP4.5 (dry seasons)
  set rice-sum_452 []                                                                      ; RCP4.5 (wet seasons)
  set rice-sum_851 []                                                                      ; RCP8.5 (dry seasons)
  set rice-sum_852 []                                                                      ; RCP8.5 (wet seasons)

  set rice-yield_1 []                                                                      ; Simulated rice yield from base data
  set rice-irrig_1 []                                                                      ; Simulated rice irrigation requirements from base data
  set rice-yield_1A []                                                                     ; Simulated rice yield from base data
  set rice-irrig_1A []                                                                     ; Simulated rice irrigation requirements from base data
  set rice-yield_1U []                                                                     ; Simulated rice yield from base data
  set rice-irrig_1U []                                                                     ; Simulated rice irrigation requirements from base data
  set rice-yield_1UA []                                                                    ; Simulated rice yield from base data
  set rice-irrig_1UA []                                                                    ; Simulated rice irrigation requirements from base data
  set rice-yield_2 []                                                                      ; Simulated rice yield from base data
  set rice-irrig_2 []                                                                      ; Simulated rice irrigation requirements from base data
  set rice-yield_2A []                                                                     ; Simulated rice yield from base data
  set rice-irrig_2A []                                                                     ; Simulated rice irrigation requirements from base data
  set rice-yield_2U []                                                                     ; Simulated rice yield from base data
  set rice-irrig_2U []                                                                     ; Simulated rice irrigation requirements from base data
  set rice-yield_2UA []                                                                    ; Simulated rice yield from base data
  set rice-irrig_2UA []                                                                    ; Simulated rice irrigation requirements from base data
  set rice-yield_451 []                                                                    ; Simulated rice yield from RCP4.5 data
  set rice-irrig_451 []                                                                    ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_451A []                                                                   ; Simulated rice yield from RCP4.5 data
  set rice-irrig_451A []                                                                   ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_451U []                                                                   ; Simulated rice yield from RCP4.5 data
  set rice-irrig_451U []                                                                   ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_451UA []                                                                  ; Simulated rice yield from RCP4.5 data
  set rice-irrig_451UA []                                                                  ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_452 []                                                                    ; Simulated rice yield from RCP4.5 data
  set rice-irrig_452 []                                                                    ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_452A []                                                                   ; Simulated rice yield from RCP4.5 data
  set rice-irrig_452A []                                                                   ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_452U []                                                                   ; Simulated rice yield from RCP4.5 data
  set rice-irrig_452U []                                                                   ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_452UA []                                                                  ; Simulated rice yield from RCP4.5 data
  set rice-irrig_452UA []                                                                  ; Simulated rice irrigation requirements from RCP4.5 data
  set rice-yield_851 []                                                                    ; Simulated rice yield from RCP8.5 data
  set rice-irrig_851 []                                                                    ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_851A []                                                                   ; Simulated rice yield from RCP8.5 data
  set rice-irrig_851A []                                                                   ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_851U []                                                                   ; Simulated rice yield from RCP8.5 data
  set rice-irrig_851U []                                                                   ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_851UA []                                                                  ; Simulated rice yield from RCP8.5 data
  set rice-irrig_851UA []                                                                  ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_852 []                                                                    ; Simulated rice yield from RCP8.5 data
  set rice-irrig_852 []                                                                    ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_852A []                                                                   ; Simulated rice yield from RCP8.5 data
  set rice-irrig_852A []                                                                   ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_852U []                                                                   ; Simulated rice yield from RCP8.5 data
  set rice-irrig_852U []                                                                   ; Simulated rice irrigation requirements from RCP8.5 data
  set rice-yield_852UA []                                                                  ; Simulated rice yield from RCP8.5 data
  set rice-irrig_852UA []                                                                  ; Simulated rice irrigation requirements from RCP8.5 data

  set rice-base-dry lput csv:from-file "1_Rice_dry_base.csv" rice-base-dry                 ; Import all rice values to a rice list (base, dry seasons)
  set rice-base-wet lput csv:from-file "2_Rice_wet_base.csv" rice-base-wet                 ; Import all rice values to a rice list (base, wet seasons)
  set rice-45-dry lput csv:from-file "3_Rice_dry_RCP45.csv" rice-45-dry                    ; Import all rice values to a rice list (RCP45, dry seasons)
  set rice-45-wet lput csv:from-file "4_Rice_wet_RCP45.csv" rice-45-wet                    ; Import all rice values to a rice list (RCP45, wet seasons)
  set rice-85-dry lput csv:from-file "5_Rice_dry_RCP85.csv" rice-85-dry                    ; Import all rice values to a rice list (RCP85, dry seasons)
  set rice-85-wet lput csv:from-file "6_Rice_wet_RCP85.csv" rice-85-wet                    ; Import all rice values to a rice list (RCP85, wet seasons)

  ; base-data processing ;;;;;;;;;
  let a 1
  while [a < 26] [                                                                         ; 3 loops for 25-year data
    foreach rice-base-dry [x -> set rice-sum_repeat1 lput item a x rice-sum_repeat1]       ; Get rid of headings of the table (starting from item 1 instead of item 0)
    foreach rice-sum_repeat1 [y -> set precip_base-dry lput item 1 y precip_base-dry]      ; Item 1 of CSV file is precipitation (dry)
    foreach rice-sum_repeat1 [y -> set rice-irrig_1 lput item 2 y rice-irrig_1]            ; Item 2 of CSV file is rice irrigation requirements (low)
    foreach rice-sum_repeat1 [y -> set rice-yield_1 lput item 3 y rice-yield_1]            ; Item 3 of CSV file is rice yield (low)
    foreach rice-sum_repeat1 [y -> set rice-irrig_1A lput item 4 y rice-irrig_1A]          ; Item 4 of CSV file is rice irrigation requirements (low, AWD)
    foreach rice-sum_repeat1 [y -> set rice-yield_1A lput item 5 y rice-yield_1A]          ; Item 5 of CSV file is rice yield (low, AWD)
    foreach rice-sum_repeat1 [y -> set rice-irrig_1U lput item 6 y rice-irrig_1U]          ; Item 6 of CSV file is rice irrigation requirements (up)
    foreach rice-sum_repeat1 [y -> set rice-yield_1U lput item 7 y rice-yield_1U]          ; Item 7 of CSV file is rice yield (up)
    foreach rice-sum_repeat1 [y -> set rice-irrig_1UA lput item 8 y rice-irrig_1UA]        ; Item 8 of CSV file is rice irrigation requirements (up, AWD)
    foreach rice-sum_repeat1 [y -> set rice-yield_1UA lput item 9 y rice-yield_1UA]        ; Item 9 of CSV file is rice yield (up, AWD)

    if length precip_base-dry != 25 [set precip_base-dry []]
    if length rice-irrig_1 != 25 [set rice-irrig_1 []]
    if length rice-yield_1 != 25 [set rice-yield_1 []]
    if length rice-irrig_1A != 25 [set rice-irrig_1A []]
    if length rice-yield_1A != 25 [set rice-yield_1A []]
    if length rice-irrig_1U != 25 [set rice-irrig_1U []]
    if length rice-yield_1U != 25 [set rice-yield_1U []]
    if length rice-irrig_1UA != 25 [set rice-irrig_1UA []]
    if length rice-yield_1UA != 25 [set rice-yield_1UA []]

    set a (a + 1)
  ]

  let b 1
  while [b < 26] [                                                                         ; 3 loops for 25-year data
    foreach rice-base-wet [x -> set rice-sum_repeat2 lput item b x rice-sum_repeat2]       ; Get rid of headings of the table (starting from item 1 instead of item 0)
    foreach rice-sum_repeat2 [y -> set precip_base-wet lput item 1 y precip_base-wet]      ; Item 1 of CSV file is precipitation (wet)
    foreach rice-sum_repeat2 [y -> set rice-irrig_2 lput item 2 y rice-irrig_2]            ; Item 2 of CSV file is rice irrigation requirements (low)
    foreach rice-sum_repeat2 [y -> set rice-yield_2 lput item 3 y rice-yield_2]            ; Item 3 of CSV file is rice yield (low)
    foreach rice-sum_repeat2 [y -> set rice-irrig_2A lput item 4 y rice-irrig_2A]          ; Item 4 of CSV file is rice irrigation requirements (low, AWD)
    foreach rice-sum_repeat2 [y -> set rice-yield_2A lput item 5 y rice-yield_2A]          ; Item 5 of CSV file is rice yield (low, AWD)
    foreach rice-sum_repeat2 [y -> set rice-irrig_2U lput item 6 y rice-irrig_2U]          ; Item 6 of CSV file is rice irrigation requirements (up)
    foreach rice-sum_repeat2 [y -> set rice-yield_2U lput item 7 y rice-yield_2U]          ; Item 7 of CSV file is rice yield (up)
    foreach rice-sum_repeat2 [y -> set rice-irrig_2UA lput item 8 y rice-irrig_2UA]        ; Item 8 of CSV file is rice irrigation requirements (up, AWD)
    foreach rice-sum_repeat2 [y -> set rice-yield_2UA lput item 9 y rice-yield_2UA]        ; Item 9 of CSV file is rice yield (up, AWD)

    if length precip_base-wet != 25 [set precip_base-wet []]
    if length rice-irrig_2 != 25 [set rice-irrig_2 []]
    if length rice-yield_2 != 25 [set rice-yield_2 []]
    if length rice-irrig_2A != 25 [set rice-irrig_2A []]
    if length rice-yield_2A != 25 [set rice-yield_2A []]
    if length rice-irrig_2U != 25 [set rice-irrig_2U []]
    if length rice-yield_2U != 25 [set rice-yield_2U []]
    if length rice-irrig_2UA != 25 [set rice-irrig_2UA []]
    if length rice-yield_2UA != 25 [set rice-yield_2UA []]

    set b (b + 1)
  ]

  ; RCPs-data processing ;;;;;;;;;;
  let c 1
  while [c < 76] [                                                                         ; for future data
    foreach rice-45-dry [x -> set rice-sum_451 lput item c x rice-sum_451]                 ; Get rid of headings of the table (starting from item 1 instead of item 0)
    foreach rice-sum_451 [y -> set precip_45-dry lput item 1 y precip_45-dry]              ; Item 1 of CSV file is precipitation (RCP4.5, dry)
    foreach rice-sum_451 [y -> set rice-irrig_451 lput item 2 y rice-irrig_451]            ; Item 2 of CSV file is rice irrigation requirements (low)
    foreach rice-sum_451 [y -> set rice-yield_451 lput item 3 y rice-yield_451]            ; Item 3 of CSV file is rice yield (low)
    foreach rice-sum_451 [y -> set rice-irrig_451A lput item 4 y rice-irrig_451A]          ; Item 4 of CSV file is rice irrigation requirements (low, AWD)
    foreach rice-sum_451 [y -> set rice-yield_451A lput item 5 y rice-yield_451A]          ; Item 5 of CSV file is rice yield (low, AWD)
    foreach rice-sum_451 [y -> set rice-irrig_451U lput item 6 y rice-irrig_451U]          ; Item 6 of CSV file is rice irrigation requirements (up)
    foreach rice-sum_451 [y -> set rice-yield_451U lput item 7 y rice-yield_451U]          ; Item 7 of CSV file is rice yield (up)
    foreach rice-sum_451 [y -> set rice-irrig_451UA lput item 8 y rice-irrig_451UA]        ; Item 8 of CSV file is rice irrigation requirements (up, AWD)
    foreach rice-sum_451 [y -> set rice-yield_451UA lput item 9 y rice-yield_451UA]        ; Item 9 of CSV file is rice yield (up, AWD)
    ;foreach rice-sum_451 [y -> set precip_45 lput item 4 y precip_45]                     ; Item x of CSV file is precipitation (RCP4.5)

    if length precip_45-dry != 75 [set precip_45-dry []]
    if length rice-irrig_451 != 75 [set rice-irrig_451 []]
    if length rice-yield_451 != 75 [set rice-yield_451 []]
    if length rice-irrig_451A != 75 [set rice-irrig_451A []]
    if length rice-yield_451A != 75 [set rice-yield_451A []]
    if length rice-irrig_451U != 75 [set rice-irrig_451U []]
    if length rice-yield_451U != 75 [set rice-yield_451U []]
    if length rice-irrig_451UA != 75 [set rice-irrig_451UA []]
    if length rice-yield_451UA != 75 [set rice-yield_451UA []]
    ;if length precip_45 != 75 [set precip_45 []]

    set c (c + 1)
  ]

  let d 1
  while [d < 76] [                                                                         ; for future data
    foreach rice-45-wet [x -> set rice-sum_452 lput item d x rice-sum_452]                 ; Get rid of headings of the table (starting from item 1 instead of item 0)
    foreach rice-sum_452 [y -> set precip_45-wet lput item 1 y precip_45-wet]              ; Item 1 of CSV file is precipitation (RCP4.5, wet)
    foreach rice-sum_452 [y -> set rice-irrig_452 lput item 2 y rice-irrig_452]            ; Item 2 of CSV file is rice irrigation requirements (low)
    foreach rice-sum_452 [y -> set rice-yield_452 lput item 3 y rice-yield_452]            ; Item 3 of CSV file is rice yield (low)
    foreach rice-sum_452 [y -> set rice-irrig_452A lput item 4 y rice-irrig_452A]          ; Item 4 of CSV file is rice irrigation requirements (low, AWD)
    foreach rice-sum_452 [y -> set rice-yield_452A lput item 5 y rice-yield_452A]          ; Item 5 of CSV file is rice yield (low, AWD)
    foreach rice-sum_452 [y -> set rice-irrig_452U lput item 6 y rice-irrig_452U]          ; Item 6 of CSV file is rice irrigation requirements (up)
    foreach rice-sum_452 [y -> set rice-yield_452U lput item 7 y rice-yield_452U]          ; Item 7 of CSV file is rice yield (up)
    foreach rice-sum_452 [y -> set rice-irrig_452UA lput item 8 y rice-irrig_452UA]        ; Item 8 of CSV file is rice irrigation requirements (up, AWD)
    foreach rice-sum_452 [y -> set rice-yield_452UA lput item 9 y rice-yield_452UA]        ; Item 9 of CSV file is rice yield (up, AWD)
    ;foreach rice-sum_452 [y -> set precip_45 lput item 4 y precip_45]                     ; Item x of CSV file is precipitation (RCP4.5)

    if length precip_45-wet != 75 [set precip_45-wet []]
    if length rice-irrig_452 != 75 [set rice-irrig_452 []]
    if length rice-yield_452 != 75 [set rice-yield_452 []]
    if length rice-irrig_452A != 75 [set rice-irrig_452A []]
    if length rice-yield_452A != 75 [set rice-yield_452A []]
    if length rice-irrig_452U != 75 [set rice-irrig_452U []]
    if length rice-yield_452U != 75 [set rice-yield_452U []]
    if length rice-irrig_452UA != 75 [set rice-irrig_452UA []]
    if length rice-yield_452UA != 75 [set rice-yield_452UA []]
    ;if length precip_45 != 75 [set precip_45 []]

    set d (d + 1)
  ]

  let m 1
  while [m < 76] [                                                                         ; for future data
    foreach rice-85-dry [x -> set rice-sum_851 lput item m x rice-sum_851]                 ; Get rid of headings of the table (starting from item 1 instead of item 0)
    foreach rice-sum_851 [y -> set precip_85-dry lput item 1 y precip_85-dry]              ; Item 1 of CSV file is precipitation (RCP8.5, dry)
    foreach rice-sum_851 [y -> set rice-irrig_851 lput item 2 y rice-irrig_851]            ; Item 2 of CSV file is rice irrigation requirements (low)
    foreach rice-sum_851 [y -> set rice-yield_851 lput item 3 y rice-yield_851]            ; Item 3 of CSV file is rice yield (low)
    foreach rice-sum_851 [y -> set rice-irrig_851A lput item 4 y rice-irrig_851A]          ; Item 4 of CSV file is rice irrigation requirements (low, AWD)
    foreach rice-sum_851 [y -> set rice-yield_851A lput item 5 y rice-yield_851A]          ; Item 5 of CSV file is rice yield (low, AWD)
    foreach rice-sum_851 [y -> set rice-irrig_851U lput item 6 y rice-irrig_851U]          ; Item 6 of CSV file is rice irrigation requirements (up)
    foreach rice-sum_851 [y -> set rice-yield_851U lput item 7 y rice-yield_851U]          ; Item 7 of CSV file is rice yield (up)
    foreach rice-sum_851 [y -> set rice-irrig_851UA lput item 8 y rice-irrig_851UA]        ; Item 8 of CSV file is rice irrigation requirements (up, AWD)
    foreach rice-sum_851 [y -> set rice-yield_851UA lput item 9 y rice-yield_851UA]        ; Item 9 of CSV file is rice yield (up, AWD)
    ;foreach rice-sum_851 [y -> set precip_85 lput item 4 y precip_85]                     ; Item x of CSV file is precipitation (RCP8.5)

    if length precip_85-dry != 75 [set precip_85-dry []]
    if length rice-irrig_851 != 75 [set rice-irrig_851 []]
    if length rice-yield_851 != 75 [set rice-yield_851 []]
    if length rice-irrig_851A != 75 [set rice-irrig_851A []]
    if length rice-yield_851A != 75 [set rice-yield_851A []]
    if length rice-irrig_851U != 75 [set rice-irrig_851U []]
    if length rice-yield_851U != 75 [set rice-yield_851U []]
    if length rice-irrig_851UA != 75 [set rice-irrig_851UA []]
    if length rice-yield_851UA != 75 [set rice-yield_851UA []]
    ;if length precip_85 != 75 [set precip_85 []]

    set m (m + 1)
  ]

  let n 1
  while [n < 76] [                                                                         ; for future data
    foreach rice-85-wet [x -> set rice-sum_852 lput item n x rice-sum_852]                 ; Get rid of headings of the table (starting from item 1 instead of item 0)
    foreach rice-sum_852 [y -> set precip_85-wet lput item 1 y precip_85-wet]              ; Item 1 of CSV file is precipitation (RCP8.5, wet)
    foreach rice-sum_852 [y -> set rice-irrig_852 lput item 2 y rice-irrig_852]            ; Item 2 of CSV file is rice irrigation requirements (low)
    foreach rice-sum_852 [y -> set rice-yield_852 lput item 3 y rice-yield_852]            ; Item 3 of CSV file is rice yield (low)
    foreach rice-sum_852 [y -> set rice-irrig_852A lput item 4 y rice-irrig_852A]          ; Item 4 of CSV file is rice irrigation requirements (low, AWD)
    foreach rice-sum_852 [y -> set rice-yield_852A lput item 5 y rice-yield_852A]          ; Item 5 of CSV file is rice yield (low, AWD)
    foreach rice-sum_852 [y -> set rice-irrig_852U lput item 6 y rice-irrig_852U]          ; Item 6 of CSV file is rice irrigation requirements (up)
    foreach rice-sum_852 [y -> set rice-yield_852U lput item 7 y rice-yield_852U]          ; Item 7 of CSV file is rice yield (up)
    foreach rice-sum_852 [y -> set rice-irrig_852UA lput item 8 y rice-irrig_852UA]        ; Item 8 of CSV file is rice irrigation requirements (up, AWD)
    foreach rice-sum_852 [y -> set rice-yield_852UA lput item 9 y rice-yield_852UA]        ; Item 9 of CSV file is rice yield (up, AWD)
    ;foreach rice-sum_852 [y -> set precip_85 lput item 4 y precip_85]                     ; Item x of CSV file is precipitation (RCP8.5)

    if length precip_85-wet != 75 [set precip_85-wet []]
    if length rice-irrig_852 != 75 [set rice-irrig_852 []]
    if length rice-yield_852 != 75 [set rice-yield_852 []]
    if length rice-irrig_852A != 75 [set rice-irrig_852A []]
    if length rice-yield_852A != 75 [set rice-yield_852A []]
    if length rice-irrig_852U != 75 [set rice-irrig_852U []]
    if length rice-yield_852U != 75 [set rice-yield_852U []]
    if length rice-irrig_852UA != 75 [set rice-irrig_852UA []]
    if length rice-yield_852UA != 75 [set rice-yield_852UA []]
    ;if length precip_85 != 75 [set precip_85 []]

    set n (n + 1)
  ]

end

to check-area                                                                              ;

  if total-area = 0 [
    set rice-yield_1 (n-values 25 [0])
    set rice-irrig_1 (n-values 25 [0])
    set rice-yield_1A (n-values 25 [0])
    set rice-irrig_1A (n-values 25 [0])
    set rice-yield_1U (n-values 25 [0])
    set rice-irrig_1U (n-values 25 [0])
    set rice-yield_1UA (n-values 25 [0])
    set rice-irrig_1UA (n-values 25 [0])
    set rice-yield_2 (n-values 25 [0])
    set rice-irrig_2 (n-values 25 [0])
    set rice-yield_2A (n-values 25 [0])
    set rice-irrig_2A (n-values 25 [0])
    set rice-yield_2U (n-values 25 [0])
    set rice-irrig_2U (n-values 25 [0])
    set rice-yield_2UA (n-values 25 [0])
    set rice-irrig_2UA (n-values 25 [0])
    set rice-yield_451 (n-values 75 [0])
    set rice-irrig_451 (n-values 75 [0])
    set rice-yield_451A (n-values 75 [0])
    set rice-irrig_451A (n-values 75 [0])
    set rice-yield_451U (n-values 75 [0])
    set rice-irrig_451U (n-values 75 [0])
    set rice-yield_451UA (n-values 75 [0])
    set rice-irrig_451UA (n-values 75 [0])
    set rice-yield_452 (n-values 75 [0])
    set rice-irrig_452 (n-values 75 [0])
    set rice-yield_452A (n-values 75 [0])
    set rice-irrig_452A (n-values 75 [0])
    set rice-yield_452U (n-values 75 [0])
    set rice-irrig_452U (n-values 75 [0])
    set rice-yield_452UA (n-values 75 [0])
    set rice-irrig_452UA (n-values 75 [0])
    set rice-yield_851 (n-values 75 [0])
    set rice-irrig_851 (n-values 75 [0])
    set rice-yield_851A (n-values 75 [0])
    set rice-irrig_851A (n-values 75 [0])
    set rice-yield_851U (n-values 75 [0])
    set rice-irrig_851U (n-values 75 [0])
    set rice-yield_851UA (n-values 75 [0])
    set rice-irrig_851UA (n-values 75 [0])
    set rice-yield_852 (n-values 75 [0])
    set rice-irrig_852 (n-values 75 [0])
    set rice-yield_852A (n-values 75 [0])
    set rice-irrig_852A (n-values 75 [0])
    set rice-yield_852U (n-values 75 [0])
    set rice-irrig_852U (n-values 75 [0])
    set rice-yield_852UA (n-values 75 [0])
    set rice-irrig_852UA (n-values 75 [0])
  ]

end

to update-farmer-behavior

  if waterlevel < 0 [
    set Management "AWD"
    show "Farmer has changed management practice to AWD due to low water availability."
  ]

end

to update-environment

end

to future-processes

  if future_climate = "RCP4.5" and Crop_seasons = "1" and Management = "As_usual"          ; RCP4.5, in-season only, as-usual

      [ifelse ticks <= 24
        [calculate-food_1-1
        calculate-water_1-1
        calculate-energy
        calculate-ghg]

        [calculate-food_2-1
        calculate-water_2-1
        calculate-energy
        calculate-ghg]
      ]

  if future_climate = "RCP8.5" and Crop_seasons = "1" and Management = "As_usual"          ; RCP8.5, in-season only, as-usual

    [ifelse ticks <= 24
      [calculate-food_1-1
      calculate-water_1-1
      calculate-energy
      calculate-ghg]

      [calculate-food_3-1
      calculate-water_3-1
      calculate-energy
      calculate-ghg]
    ]

  if future_climate = "RCP4.5" and Crop_seasons = "1" and Management = "AWD"               ; RCP4.5, in-season only, as-usual

      [ifelse ticks <= 24
        [calculate-food_1-2
        calculate-water_1-2
        calculate-energy
        calculate-ghg]

        [calculate-food_2-2
        calculate-water_2-2
        calculate-energy
        calculate-ghg]
      ]

  if future_climate = "RCP8.5" and Crop_seasons = "1" and Management = "AWD"               ; RCP8.5, in-season only, as-usual

    [ifelse ticks <= 24
      [calculate-food_1-2
      calculate-water_1-2
      calculate-energy
      calculate-ghg]

      [calculate-food_3-2
      calculate-water_3-2
      calculate-energy
      calculate-ghg]
    ]

  if future_climate = "RCP4.5" and Crop_seasons = "2" and Management = "As_usual"          ; RCP4.5, both seasons, as-usual

      [ifelse ticks <= 24
        [calculate-food_1-3
        calculate-water_1-3
        calculate-energy
        calculate-ghg]

        [calculate-food_2-3
        calculate-water_2-3
        calculate-energy
        calculate-ghg]
      ]

  if future_climate = "RCP8.5" and Crop_seasons = "2" and Management = "As_usual"          ; RCP8.5, both seasons, as-usual

    [ifelse ticks <= 24
      [calculate-food_1-3
      calculate-water_1-3
      calculate-energy
      calculate-ghg]

      [calculate-food_3-3
      calculate-water_3-3
      calculate-energy
      calculate-ghg]
    ]

  if future_climate = "RCP4.5" and Crop_seasons = "2" and Management = "AWD"               ; RCP4.5, both seasons, as-usual

      [ifelse ticks <= 24
        [calculate-food_1-4
        calculate-water_1-4
        calculate-energy
        calculate-ghg]

        [calculate-food_2-4
        calculate-water_2-4
        calculate-energy
        calculate-ghg]
      ]

  if future_climate = "RCP8.5" and Crop_seasons = "2" and Management = "AWD"               ; RCP8.5, both seasons, as-usual

    [ifelse ticks <= 24
      [calculate-food_1-4
      calculate-water_1-4
      calculate-energy
      calculate-ghg]

      [calculate-food_3-4
      calculate-water_3-4
      calculate-energy
      calculate-ghg]
    ]

end

to calculate-food_1-1                                                                      ; Base, in-season only, as-usual

  let n (ticks)
  set rice-tot-yield (item n rice-yield_2)
  set rice-tot-income (item n rice-yield_2 * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_1-2                                                                      ; Base, in-season only, AWD

  let n (ticks)
  set rice-tot-yield (item n rice-yield_2A)
  set rice-tot-income (item n rice-yield_2A * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_1-3                                                                      ; Base, combined seasons, as-usual

  let n (ticks)
  set rice-tot-yield ((item n rice-yield_1) + (item n rice-yield_2))
  set rice-tot-income (((item n rice-yield_1) + (item n rice-yield_2)) * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_1-4                                                                      ; Base, combined seasons, AWD

  let n (ticks)
  set rice-tot-yield ((item n rice-yield_1A) + (item n rice-yield_2A))
  set rice-tot-income (((item n rice-yield_1A) + (item n rice-yield_2A)) * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_2-1                                                                      ; RCP4.5, in-season only, as-usual

  let m (ticks - 25)
  set rice-tot-yield (item m rice-yield_452)
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_2-2                                                                      ; RCP4.5, in-season only, AWD

  let m (ticks - 25)
  set rice-tot-yield (item m rice-yield_452A)
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_2-3                                                                      ; RCP4.5, combined seasons, as-usual

  let m (ticks - 25)
  set rice-tot-yield ((item m rice-yield_451) + (item m rice-yield_452))
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_2-4                                                                      ; RCP4.5, combined seasons, AWD

  let m (ticks - 25)
  set rice-tot-yield ((item m rice-yield_451A) + (item m rice-yield_452A))
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_3-1                                                                      ; RCP8.5, in-season only, as-usual

  let o (ticks - 25)
  set rice-tot-yield (item o rice-yield_852)
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_3-2                                                                      ; RCP8.5, in-season only, AWD

  let o (ticks - 25)
  set rice-tot-yield (item o rice-yield_852A)
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_3-3                                                                      ; RCP8.5, combined seasons, as-usual

  let o (ticks - 25)
  set rice-tot-yield ((item o rice-yield_851) + (item o rice-yield_852))
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-food_3-4                                                                      ; RCP8.5, combined seasons, AWD

  let o (ticks - 25)
  set rice-tot-yield ((item o rice-yield_851A) + (item o rice-yield_852A))
  set rice-tot-income (rice-tot-yield * rice-price * total-area)

  calculate-expenses-yield
  calculate-net-income

end

to calculate-water_1-1                                                                     ; Base, in-season only, as-usual

  let a ticks
  set rice-irreq (item a rice-irrig_2 * 10)                                                ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_1-2                                                                     ; Base, in-season only, AWD

  let a ticks
  set rice-irreq (item a rice-irrig_2A * 10)                                               ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_1-3                                                                     ; Base, combined seasons, as-usual

  let a ticks
  set rice-irreq (((item a rice-irrig_1) + (item a rice-irrig_2)) * 10)                    ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_1-4                                                                     ; Base, combined seasons, AWD

  let a ticks
  set rice-irreq (((item a rice-irrig_1A) + (item a rice-irrig_2A)) * 10)                  ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_2-1

  let b (ticks - 25)
  set rice-irreq (item b rice-irrig_452 * 10)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_2-2

  let b (ticks - 25)
  set rice-irreq (item b rice-irrig_452A * 10)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_2-3

  let b (ticks - 25)
  set rice-irreq (((item b rice-irrig_451) + (item b rice-irrig_452)) * 10)                ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_2-4

  let b (ticks - 25)
  set rice-irreq (((item b rice-irrig_451A) + (item b rice-irrig_452A)) * 10)              ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_3-1

  let c (ticks - 25)
  set rice-irreq (item c rice-irrig_852 * 10)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_3-2

  let c (ticks - 25)
  set rice-irreq (item c rice-irrig_852A * 10)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_3-3

  let c (ticks - 25)
  set rice-irreq (((item c rice-irrig_851) + (item c rice-irrig_852)) * 10)                ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-water_3-4

  let c (ticks - 25)
  set rice-irreq (((item c rice-irrig_851A) + (item c rice-irrig_852A)) * 10)              ; convert mm to m3/ha (10 m3/ha = 1 mm/m2)
  set total-water-use (rice-irreq * total-area)

  calculate-total-water-available
  calculate-waterlevel-change

end

to calculate-energy

  ; calculate solar energy (surface water and storage) ;;;;;;;;;;
  ; solar production ;
  ifelse Use_solar_energy_for_SW? = True and Use_surfacewater? = True
  [ if count-solar-lifespan_SW <= sol_lifespan_SW
    [ ifelse count-solar-lifespan_SW = 0
      [ set solar-production-temp_SW (sol_capacity_SW * sun_hours_SW * 365 / 1000000)
        set solar-production_SW (solar-production-temp_SW)
        set count-solar-lifespan_SW (count-solar-lifespan_SW + 1) ]
      [ set solar-production_SW ((1 - (degradation_SW / 100)) * solar-production-temp_SW)
        set solar-production-temp_SW (solar-production_SW)
        set count-solar-lifespan_SW (count-solar-lifespan_SW + 1)
        if count-solar-lifespan_SW = sol_lifespan_SW [set count-solar-lifespan_SW 0] ]
    ]
  ]
  [ set solar-production_SW 0 ]

  ; solar financial ;
  ifelse Use_solar_energy_for_SW? = True and Use_surfacewater? = True
  [ if count-solar-lifespan-cost_SW <= sol_lifespan_SW + 1
    [ set solar-cost-temp_SW (sol_install_cost_SW + (1 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * count-solar-lifespan-cost_SW))
      set acc-solar-cost_SW solar-cost-temp_SW
      set count-solar-lifespan-cost_SW (count-solar-lifespan-cost_SW + 1)
    ]
    if count-solar-lifespan-cost_SW > sol_lifespan_SW + 1 and count-solar-lifespan-cost_SW <= (sol_lifespan_SW * 2) + 2
    [ set solar-cost-temp_SW ((2 * sol_install_cost_SW) + (3 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 1)))
      set acc-solar-cost_SW solar-cost-temp_SW
      set count-solar-lifespan-cost_SW (count-solar-lifespan-cost_SW + 1)
    ]
    if count-solar-lifespan-cost_SW > (sol_lifespan_SW * 2) + 2 and count-solar-lifespan-cost_SW <= (sol_lifespan_SW * 3) + 3
    [ set solar-cost-temp_SW ((3 * sol_install_cost_SW) + (5 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 2)))
      set acc-solar-cost_SW solar-cost-temp_SW
      set count-solar-lifespan-cost_SW (count-solar-lifespan-cost_SW + 1)
    ]
    if count-solar-lifespan-cost_SW > (sol_lifespan_SW * 3) + 3 and count-solar-lifespan-cost_SW <= (sol_lifespan_SW * 4) + 4
    [ set solar-cost-temp_SW ((4 * sol_install_cost_SW) + (7 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 3)))
      set acc-solar-cost_SW solar-cost-temp_SW
      set count-solar-lifespan-cost_SW (count-solar-lifespan-cost_SW + 1)
    ]
    if count-solar-lifespan-cost_SW > (sol_lifespan_SW * 4) + 4
    [ set solar-cost-temp_SW ((5 * sol_install_cost_SW) + (9 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 4)))
      set acc-solar-cost_SW solar-cost-temp_SW
      set count-solar-lifespan-cost_SW (count-solar-lifespan-cost_SW + 1)
    ]
    if count-solar-lifespan-cost_SW > (sol_pump_lifespan_SW * 1) + 1 and count-solar-lifespan-cost_SW <= (sol_pump_lifespan_SW * 2) + 2
    [ set solar-cost-temp_SW ((1 * sol_install_cost_SW) + (2 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 1)))
      set acc-solar-cost_SW solar-cost-temp_SW
    ]
    if count-solar-lifespan-cost_SW > (sol_pump_lifespan_SW * 3) + 3 and count-solar-lifespan-cost_SW <= (sol_pump_lifespan_SW * 4) + 4
    [ set solar-cost-temp_SW ((2 * sol_install_cost_SW) + (4 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 2)))
      set acc-solar-cost_SW solar-cost-temp_SW
    ]
    if count-solar-lifespan-cost_SW > (sol_pump_lifespan_SW * 5) + 5 and count-solar-lifespan-cost_SW <= (sol_pump_lifespan_SW * 6) + 6
    [ set solar-cost-temp_SW ((3 * sol_install_cost_SW) + (6 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 3)))
      set acc-solar-cost_SW solar-cost-temp_SW
    ]
    if count-solar-lifespan-cost_SW > (sol_pump_lifespan_SW * 7) + 7 and count-solar-lifespan-cost_SW <= (sol_pump_lifespan_SW * 8) + 8
    [ set solar-cost-temp_SW ((4 * sol_install_cost_SW) + (8 * Sol_pump_install_cost_SW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_SW - 4)))
      set acc-solar-cost_SW solar-cost-temp_SW
    ]
  ]
  [ set acc-solar-cost_SW 0 ]

  ; calculate solar energy (groundwater) ;;;;;;;;;;
  ; solar production ;
  ifelse Use_solar_energy_for_GW? = True and Use_groundwater? = True
  [ if count-solar-lifespan_GW <= sol_lifespan_GW
    [ ifelse count-solar-lifespan_GW = 0
      [ set solar-production-temp_GW (sol_capacity_GW * sun_hours_GW * 365 / 1000000)
        set solar-production_GW (solar-production-temp_GW)
        set count-solar-lifespan_GW (count-solar-lifespan_GW + 1) ]
      [ set solar-production_GW ((1 - (degradation_GW / 100)) * solar-production-temp_GW)
        set solar-production-temp_GW (solar-production_GW)
        set count-solar-lifespan_GW (count-solar-lifespan_GW + 1)
        if count-solar-lifespan_GW = sol_lifespan_GW [set count-solar-lifespan_GW 0] ]
    ]
  ]
  [ set solar-production_GW 0 ]

  ; solar financial ;
  ifelse Use_solar_energy_for_GW? = True and Use_groundwater? = True
  [ if count-solar-lifespan-cost_GW <= sol_lifespan_GW + 1
    [ set solar-cost-temp_GW (sol_install_cost_GW + (1 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * count-solar-lifespan-cost_GW))
      set acc-solar-cost_GW solar-cost-temp_GW
      set count-solar-lifespan-cost_GW (count-solar-lifespan-cost_GW + 1)
    ]
    if count-solar-lifespan-cost_GW > sol_lifespan_GW + 1 and count-solar-lifespan-cost_GW <= (sol_lifespan_GW * 2) + 2
    [ set solar-cost-temp_GW ((2 * sol_install_cost_GW) + (3 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 1)))
      set acc-solar-cost_GW solar-cost-temp_GW
      set count-solar-lifespan-cost_GW (count-solar-lifespan-cost_GW + 1)
    ]
    if count-solar-lifespan-cost_GW > (sol_lifespan_GW * 2) + 2 and count-solar-lifespan-cost_GW <= (sol_lifespan_GW * 3) + 3
    [ set solar-cost-temp_GW ((3 * sol_install_cost_GW) + (5 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 2)))
      set acc-solar-cost_GW solar-cost-temp_GW
      set count-solar-lifespan-cost_GW (count-solar-lifespan-cost_GW + 1)
    ]
    if count-solar-lifespan-cost_GW > (sol_lifespan_GW * 3) + 3 and count-solar-lifespan-cost_GW <= (sol_lifespan_GW * 4) + 4
    [ set solar-cost-temp_GW ((4 * sol_install_cost_GW) + (7 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 3)))
      set acc-solar-cost_GW solar-cost-temp_GW
      set count-solar-lifespan-cost_GW (count-solar-lifespan-cost_GW + 1)
    ]
    if count-solar-lifespan-cost_GW > (sol_lifespan_GW * 4) + 4
    [ set solar-cost-temp_GW ((5 * sol_install_cost_GW) + (9 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 4)))
      set acc-solar-cost_GW solar-cost-temp_GW
      set count-solar-lifespan-cost_GW (count-solar-lifespan-cost_GW + 1)
    ]
    if count-solar-lifespan-cost_GW > (sol_pump_lifespan_GW * 1) + 1 and count-solar-lifespan-cost_GW <= (sol_pump_lifespan_GW * 2) + 2
    [ set solar-cost-temp_GW ((1 * sol_install_cost_GW) + (2 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 1)))
      set acc-solar-cost_GW solar-cost-temp_GW
    ]
    if count-solar-lifespan-cost_GW > (sol_pump_lifespan_GW * 3) + 3 and count-solar-lifespan-cost_GW <= (sol_pump_lifespan_GW * 4) + 4
    [ set solar-cost-temp_GW ((2 * sol_install_cost_GW) + (4 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 2)))
      set acc-solar-cost_GW solar-cost-temp_GW
    ]
    if count-solar-lifespan-cost_GW > (sol_pump_lifespan_GW * 5) + 5 and count-solar-lifespan-cost_GW <= (sol_pump_lifespan_GW * 6) + 6
    [ set solar-cost-temp_GW ((3 * sol_install_cost_GW) + (6 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 3)))
      set acc-solar-cost_GW solar-cost-temp_GW
    ]
    if count-solar-lifespan-cost_GW > (sol_pump_lifespan_GW * 7) + 7 and count-solar-lifespan-cost_GW <= (sol_pump_lifespan_GW * 8) + 8
    [ set solar-cost-temp_GW ((4 * sol_install_cost_GW) + (8 * Sol_pump_install_cost_GW) + (sol_maintain_cost_SW * (count-solar-lifespan-cost_GW - 4)))
      set acc-solar-cost_GW solar-cost-temp_GW
    ]
  ]
  [ set acc-solar-cost_GW 0 ]

  ; calculate fossil fuels (surface water and storage) ;;;;;;;;;;
  ; fossil fuels financial ;
  ifelse Use_fossil_fuels? = True and Use_surfacewater? = True
  [ if count-fossil-lifespan <= Fuelpump_lifespan + 1
    [ set fossil-cost-temp (fuelpump_cost + ((fuel_price * fuel_consumption * count-fossil-lifespan) + (fuel_maintain_cost * count-fossil-lifespan)))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > Fuelpump_lifespan + 1 and count-fossil-lifespan <= (Fuelpump_lifespan * 2) + 2
    [ set fossil-cost-temp ((2 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 1)) + (fuel_maintain_cost * (count-fossil-lifespan - 1))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 2) + 2 and count-fossil-lifespan <= (Fuelpump_lifespan * 3) + 3
    [ set fossil-cost-temp ((3 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 2)) + (fuel_maintain_cost * (count-fossil-lifespan - 2))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 3) + 3 and count-fossil-lifespan <= (Fuelpump_lifespan * 4) + 4
    [ set fossil-cost-temp ((4 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 3)) + (fuel_maintain_cost * (count-fossil-lifespan - 3))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 4) + 4 and count-fossil-lifespan <= (Fuelpump_lifespan * 5) + 5
    [ set fossil-cost-temp ((5 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 4)) + (fuel_maintain_cost * (count-fossil-lifespan - 4))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 5) + 5 and count-fossil-lifespan <= (Fuelpump_lifespan * 6) + 6
    [ set fossil-cost-temp ((6 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 5)) + (fuel_maintain_cost * (count-fossil-lifespan - 5))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 6) + 6 and count-fossil-lifespan <= (Fuelpump_lifespan * 7) + 7
    [ set fossil-cost-temp ((7 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 6)) + (fuel_maintain_cost * (count-fossil-lifespan - 6))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 7) + 7 and count-fossil-lifespan <= (Fuelpump_lifespan * 8) + 8
    [ set fossil-cost-temp ((8 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 7)) + (fuel_maintain_cost * (count-fossil-lifespan - 7))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 8) + 8 and count-fossil-lifespan <= (Fuelpump_lifespan * 9) + 9
    [ set fossil-cost-temp ((9 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 8)) + (fuel_maintain_cost * (count-fossil-lifespan - 8))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 9) + 9 and count-fossil-lifespan <= (Fuelpump_lifespan * 10) + 10
    [ set fossil-cost-temp ((10 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 9)) + (fuel_maintain_cost * (count-fossil-lifespan - 9))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
    if count-fossil-lifespan > (Fuelpump_lifespan * 10) + 10
    [ set fossil-cost-temp ((11 * fuelpump_cost) + ((fuel_price * fuel_consumption * (count-fossil-lifespan - 10)) + (fuel_maintain_cost * (count-fossil-lifespan - 10))))
      set acc-fossil-cost fossil-cost-temp
      set count-fossil-lifespan (count-fossil-lifespan + 1)
    ]
  ]
  [ set acc-fossil-cost 0 ]

  ; calculate electricity (groundwater) ;;;;;;;;;;
  ; electricity financial ;
  ifelse Use_electricity? = True and Use_groundwater? = True
  [ if count-elec-lifespan <= Elec_pump_lifespan + 1
    [ set elec-cost-temp (elec_install_cost_GW + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan)) + (elec_maintain_cost * count-elec-lifespan))) ; Ft = 2.82182 THB/kWh, Convert Wh to kWh by dividing by 1000
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > Elec_pump_lifespan + 1 and count-elec-lifespan <= (Elec_pump_lifespan * 2) + 2
    [ set elec-cost-temp ((2 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 1)) + (elec_maintain_cost * (count-elec-lifespan - 1))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 2) + 2 and count-elec-lifespan <= (Elec_pump_lifespan * 3) + 3
    [ set elec-cost-temp ((3 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 2)) + (elec_maintain_cost * (count-elec-lifespan - 2))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 3) + 3 and count-elec-lifespan <= (Elec_pump_lifespan * 4) + 4
    [ set elec-cost-temp ((4 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 3)) + (elec_maintain_cost * (count-elec-lifespan - 3))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 4) + 4 and count-elec-lifespan <= (Elec_pump_lifespan * 5) + 5
    [ set elec-cost-temp ((5 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 4)) + (elec_maintain_cost * (count-elec-lifespan - 4))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 5) + 5 and count-elec-lifespan <= (Elec_pump_lifespan * 6) + 6
    [ set elec-cost-temp ((6 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 5)) + (elec_maintain_cost * (count-elec-lifespan - 5))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 6) + 6 and count-elec-lifespan <= (Elec_pump_lifespan * 7) + 7
    [ set elec-cost-temp ((7 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 6)) + (elec_maintain_cost * (count-elec-lifespan - 6))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 7) + 7 and count-elec-lifespan <= (Elec_pump_lifespan * 8) + 8
    [ set elec-cost-temp ((8 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 7)) + (elec_maintain_cost * (count-elec-lifespan - 7))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 8) + 8 and count-elec-lifespan <= (Elec_pump_lifespan * 9) + 9
    [ set elec-cost-temp ((9 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 8)) + (elec_maintain_cost * (count-elec-lifespan - 8))))
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 9) + 9 and count-elec-lifespan <= (Elec_pump_lifespan * 10) + 10
    [ set elec-cost-temp ((10 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 9)) + (elec_maintain_cost * (count-elec-lifespan - 9))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
    if count-elec-lifespan > (Elec_pump_lifespan * 10) + 10
    [ set elec-cost-temp ((11 * elec_install_cost_GW) + ((Elec_pump_watt_GW * Groundwater_pump_hours * Groundwater_pump_day * 2.4 / 1000 * (count-elec-lifespan - 10)) + (elec_maintain_cost * (count-elec-lifespan - 10))))
      set acc-elec-cost elec-cost-temp
      set count-elec-lifespan (count-elec-lifespan + 1)
    ]
  ]
  [ set acc-elec-cost 0 ]

  set acc-energy-costs (acc-solar-cost_SW + acc-solar-cost_GW + acc-fossil-cost + acc-elec-cost)

end

to calculate-expenses-yield

  set rice-expenses ((rice-costs * total-area ) + (energy-costs * total-area))

end

to calculate-net-income

  set rice-net-income (rice-tot-income - rice-expenses)

end

to calculate-total-water-available

  set total-water-available (storage-availability + gw-availability)

end

to calculate-waterlevel-change

  set waterlevel (total-water-available - total-water-use)
  set total-water-available (storage-availability + gw-availability)

end

to calculate-ghg

  ; calculate ghg from field burning (3C1b) ;;;;;;;;;;
  ; rice only ;
  let m ticks + 1
  set area-burnt Burning_area
  set burn-emission-co2 (m * area-burnt * 5.5 * 1515 * 10e-3)     ; (Lfire = A x MB x Cf x Gef x 10e-3), MB x Cf for rice straw = 5.5, Gef for CO2 = 1515 (IPCC, 2006)
  set burn-emission-ch4 (m * area-burnt * 5.5 * 2.7 * 10e-3)      ; Gef for CH4 = 2.7 (IPCC, 2006)

  ; calculate ghg from urea fertilization (3C3) ;;;;;;;;;;
  let n ticks + 1
  set urea-emission-co2 (n * applied_urea_fertilizer * 0.2)       ; (CO2-C emission = M x EF), Recommended EF = 0.2 (IPCC, 2006)

  ; calculate ghg from rice farming (3C7) ;;;;;;;;;;
  ; scaling factor for water regime (sfw) ;
  if rice_water_regime = "Irrigated, Continuously flooded" [ set sfw 1 ]
  if rice_water_regime = "Irrigated, Single drainage" [ set sfw 0.71 ]
  if rice_water_regime = "Irrigated, Multiple drainage" [ set sfw 0.55 ]
  if rice_water_regime = "Rainfed, Regular" [ set sfw 0.54 ]
  if rice_water_regime = "Rainfed, Drought prone" [ set sfw 0.16 ]
  if rice_water_regime = "Deepwater" [ set sfw 0.06 ]

  ; scaling factor for pre-season water regime (sfp) ;
  if rice_pre-season_water_regime = ">180 days non-flooded" [ set sfp 0.89 ]
  if rice_pre-season_water_regime = "<180 days non-flooded" [ set sfp 1 ]
  if rice_pre-season_water_regime = ">30 days flooded" [ set sfp 2.41 ]

  ; scaling factor for organic amendment (sfo) ;
  if organic_amendment = ">30 days straw" [ set cfoa 0.19 ]
  if organic_amendment = "<30 days straw" [ set cfoa 1 ]
  set roa organic_amendment_weight
  set sfo (1 + roa * cfoa)^ 0.59                                   ; (SFo = (1 + ROA x CFOA)^ 0.59)

  ; emission factors (ef) ;
  ifelse organic_amendment = "Not applied"                         ; (EF = EFc x SFw x SFp x SFo), EFc = 1.22 for Southeast Asia (IPCC, 2019)
  [ set efactor-rice (1.22 * sfw * sfp) ]
  [ set efactor-rice (1.22 * sfw * sfp * sfo) ]

  ; methane release from rice cultivation (CH4 rice);
  let o ticks + 1
  set rice-emission-ch4-single (o * efactor-rice * total-area * 10e-3 * 28) ; (CH4rice = EF * A * 10^ -3 * GWP), GWP for methane = 28
  set rice-emission-ch4 rice-emission-ch4-single

end
@#$#@#$#@
GRAPHICS-WINDOW
414
38
824
449
-1
-1
2.0
1
14
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
Years
30.0

BUTTON
192
30
256
63
Setup
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
260
30
323
63
Go
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

TEXTBOX
345
11
391
29
Settings
12
0.0
1

BUTTON
327
30
390
63
Go once
go
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
303
67
390
100
Restore default
restore-default
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
30
188
63
simulation_period
simulation_period
1
100
100.0
1
1
Years
HORIZONTAL

CHOOSER
8
67
152
112
future_climate
future_climate
"RCP4.5" "RCP8.5"
0

CHOOSER
153
67
299
112
Management
Management
"As_usual" "AWD"
1

TEXTBOX
9
118
159
136
- - - - - Agriculture - - - - -
11
55.0
1

INPUTBOX
8
135
124
195
Rice_area
1.0
1
0
Number

TEXTBOX
9
202
171
230
- - - - - Water - - - - -
11
95.0
1

SLIDER
207
233
401
266
Surfacewater_pump_rate
Surfacewater_pump_rate
0
100
50.0
1
1
m3/hr
HORIZONTAL

SLIDER
207
461
401
494
Groundwater_pump_rate
Groundwater_pump_rate
0
25
5.0
1
1
m3/hr
HORIZONTAL

SLIDER
207
323
401
356
Storage_pump_rate
Storage_pump_rate
0
100
25.0
1
1
m3/d
HORIZONTAL

INPUTBOX
285
397
401
457
Storage_capacity
5000.0
1
0
Number

TEXTBOX
435
478
585
496
- - - - - Energy - - - - -
11
15.0
1

SLIDER
632
585
828
618
#users_SW
#users_SW
1
50
1.0
1
1
users
HORIZONTAL

SLIDER
434
548
628
581
Sol_capacity_SW
Sol_capacity_SW
100
5000
2400.0
50
1
W
HORIZONTAL

SLIDER
434
585
628
618
Sun_hours_SW
Sun_hours_SW
0
10
4.4
0.1
1
hrs/day
HORIZONTAL

SLIDER
632
511
828
544
Sol_lifespan_SW
Sol_lifespan_SW
20
30
25.0
1
1
years
HORIZONTAL

SLIDER
632
548
828
581
Degradation_SW
Degradation_SW
0
1
0.5
0.1
1
%/year
HORIZONTAL

INPUTBOX
594
622
709
682
Sol_install_cost_SW
11500.0
1
0
Number

INPUTBOX
475
622
590
682
Sol_maintain_cost_SW
500.0
1
0
Number

INPUTBOX
102
622
192
682
Fuel_price
30.0
1
0
Number

INPUTBOX
196
622
309
682
Fuel_consumption
40.0
1
0
Number

TEXTBOX
501
10
736
44
The Farm Management Platform 1.0.0
14
0.0
1

PLOT
837
29
1157
173
Yearly rice yield
Years
kg/ha
0.0
100.0
0.0
15000.0
false
true
"set-plot-background-color 44" ""
PENS
"Rice yield" 1.0 0 -2674135 true "" "if ticks >= 1\n[ plot rice-tot-yield ]"

PLOT
837
473
1157
617
Yearly financial
Years
THB
0.0
100.0
0.0
80000.0
false
true
"set-plot-background-color 9" ""
PENS
"Net income" 1.0 0 -2674135 true "" "if ticks >= 1\n[ plot (rice-tot-income - rice-expenses) ]"
"THB 0" 1.0 0 -16777216 true "" "plot zero-line"

PLOT
837
325
1157
469
Available water
Years
m3
0.0
100.0
0.0
100.0
true
true
"set-plot-background-color 106" ""
PENS
"Water avail." 1.0 0 -2674135 true "" "if ticks >= 1\n[plot waterlevel]"
"Level 0" 1.0 0 -16777216 true "" "plot zero-line"

PLOT
837
769
1157
913
Accumulated methane emissions
Year
tCO2e
0.0
100.0
0.0
5.0
true
true
"set-plot-background-color 117" ""
PENS
"Methane" 1.0 0 -2674135 true "" "plot rice-emission-ch4"

SWITCH
434
511
628
544
Use_solar_energy_for_SW?
Use_solar_energy_for_SW?
1
1
-1000

SWITCH
8
703
202
736
Use_electricity?
Use_electricity?
1
1
-1000

SWITCH
8
585
202
618
Use_fossil_fuels?
Use_fossil_fuels?
0
1
-1000

SWITCH
8
233
202
266
Use_surfacewater?
Use_surfacewater?
0
1
-1000

SWITCH
8
461
202
494
Use_groundwater?
Use_groundwater?
1
1
-1000

CHOOSER
128
150
245
195
Unit_area
Unit_area
"Hectare" "Rai"
0

TEXTBOX
137
135
287
153
1 Hectare = 6.25 Rai
11
0.0
1

TEXTBOX
371
426
397
444
(m3)
11
0.0
1

TEXTBOX
675
651
704
669
(THB)
11
0.0
1

TEXTBOX
529
651
583
679
(THB/year)
11
0.0
1

TEXTBOX
135
651
187
669
(THB/liter)
11
0.0
1

TEXTBOX
249
651
306
669
(liter/year)
11
0.0
1

TEXTBOX
837
10
987
28
Output
12
0.0
1

TEXTBOX
414
11
476
29
Display
12
0.0
1

PLOT
837
621
1157
765
Accumulated energy costs
Year
THB
0.0
100.0
0.0
250000.0
true
true
"set-plot-background-color 9" ""
PENS
"Solar (SW)" 1.0 0 -16777216 false "" ";plot acc-solar-cost_SW"
"Solar (GW)" 1.0 0 -7500403 false "" ";plot acc-solar-cost_GW"
"Elec (GW)" 1.0 0 -2674135 false "" ";plot acc-elec-cost"
"Fuel (SW)" 1.0 0 -955883 false "" ";plot acc-fossil-cost"
"Off, No adap" 1.0 0 -6459832 true "" "plot (acc-elec-cost + acc-fossil-cost)"
"Off, Adap" 1.0 0 -14835848 true "" "plot (acc-solar-cost_GW + acc-solar-cost_SW)"

TEXTBOX
10
805
204
834
- - - - - GHG - Farm activities - - - - -
11
35.0
1

INPUTBOX
8
871
138
931
Burning_area
0.0
1
0
Number

INPUTBOX
144
871
274
931
Applied_urea_fertilizer
0.0
1
0
Number

CHOOSER
8
821
196
866
Rice_water_regime
Rice_water_regime
"Irrigated, Continuously flooded" "Irrigated, Single drainage" "Irrigated, Multiple drainage" "Rainfed, Regular" "Rainfed, Drought prone" "Deepwater"
2

CHOOSER
202
821
390
866
Rice_pre-season_water_regime
Rice_pre-season_water_regime
">180 days non-flooded" "<180 days non-flooded" ">30 days flooded"
1

CHOOSER
395
821
546
866
Organic_amendment
Organic_amendment
"Not applied" ">30 days straw" "<30 days straw"
0

INPUTBOX
415
871
546
931
Organic_amendment_weight
0.0
1
0
Number

INPUTBOX
278
871
409
931
Cultivation_period
110.0
1
0
Number

MONITOR
1162
228
1253
273
CH4 emission
rice-emission-ch4
2
1
11

INPUTBOX
164
397
280
457
Groundwater_yield
5.0
1
0
Number

TEXTBOX
236
426
280
444
(m3/hr)
11
0.0
1

TEXTBOX
9
533
261
563
Groundwater_yield - Browse groundwater database\nhttp://app.dgr.go.th/newpasutara/xml/search.php
11
95.0
1

SWITCH
8
323
202
356
Unlimited_storage?
Unlimited_storage?
1
1
-1000

SLIDER
207
360
401
393
Storage_pump_day
Storage_pump_day
0
366
30.0
1
1
d/yr
HORIZONTAL

SLIDER
207
498
401
531
Groundwater_pump_day
Groundwater_pump_day
0
366
100.0
1
1
d/yr
HORIZONTAL

SLIDER
207
270
401
303
Surfacewater_pump_day
Surfacewater_pump_day
0
366
30.0
1
1
d/yr
HORIZONTAL

MONITOR
1162
868
1253
913
Storage
storage-availability
17
1
11

MONITOR
1162
819
1253
864
Groundwater
gw-availability
17
1
11

MONITOR
1162
128
1253
173
Total water
waterlevel
17
1
11

MONITOR
1162
572
1253
617
Acc solar cost (SW)
acc-solar-cost_SW
17
1
11

TEXTBOX
261
533
425
561
Groundwater_pump_rate must not exceed Groundwater_yield
11
125.0
1

SLIDER
8
270
202
303
Surfacewater_pump_hours
Surfacewater_pump_hours
0
8
5.0
1
1
hr/d
HORIZONTAL

SLIDER
8
360
202
393
Storage_pump_hours
Storage_pump_hours
0
8
5.0
1
1
hr/d
HORIZONTAL

SLIDER
8
498
202
531
Groundwater_pump_hours
Groundwater_pump_hours
0
8
5.0
1
1
hr/d
HORIZONTAL

TEXTBOX
9
216
165
244
Water - Surface water pumping
11
95.0
1

TEXTBOX
9
568
320
586
Energy - Fossil fuels for Surface water and Storage pumping
11
15.0
1

TEXTBOX
8
306
158
324
Water - Storage pumping
11
95.0
1

TEXTBOX
9
444
159
476
Water - Groundwater pumping
11
95.0
1

INPUTBOX
8
622
98
682
Fuelpump_cost
10000.0
1
0
Number

INPUTBOX
313
622
426
682
Fuel_maintain_cost
140.0
1
0
Number

TEXTBOX
63
651
95
669
(THB)
11
0.0
1

TEXTBOX
365
651
422
669
(THB/year)
11
0.0
1

SLIDER
206
585
400
618
Fuelpump_lifespan
Fuelpump_lifespan
10
15
12.5
0.5
1
years
HORIZONTAL

TEXTBOX
434
493
740
511
Energy - Solar energy for Surface water and Storage pumping
11
15.0
1

TEXTBOX
9
686
315
704
Energy - Electricity for Groundwater pumping
11
15.0
1

SWITCH
434
703
628
736
Use_solar_energy_for_GW?
Use_solar_energy_for_GW?
1
1
-1000

SLIDER
8
740
202
773
Elec_pump_watt_GW
Elec_pump_watt_GW
100
3000
1100.0
50
1
W
HORIZONTAL

SLIDER
632
703
826
736
Sol_lifespan_GW
Sol_lifespan_GW
20
30
25.0
1
1
years
HORIZONTAL

SLIDER
434
740
628
773
Sol_capacity_GW
Sol_capacity_GW
100
5000
2400.0
50
1
W
HORIZONTAL

INPUTBOX
207
740
314
800
Elec_install_cost_GW
17000.0
1
0
Number

INPUTBOX
592
814
707
874
Sol_install_cost_GW
8000.0
1
0
Number

TEXTBOX
279
769
309
787
(THB)
11
0.0
1

TEXTBOX
672
843
730
861
(THB)
11
0.0
1

SLIDER
632
740
826
773
Degradation_GW
Degradation_GW
0
1
0.5
0.1
1
%/year
HORIZONTAL

SLIDER
434
777
628
810
Sun_hours_GW
Sun_hours_GW
0
10
4.4
0.1
1
hrs/day
HORIZONTAL

SLIDER
632
777
826
810
#users_GW
#users_GW
1
50
1.0
1
1
users
HORIZONTAL

SLIDER
207
703
401
736
Elec_pump_lifespan
Elec_pump_lifespan
10
15
12.5
0.5
1
years
HORIZONTAL

TEXTBOX
435
686
672
704
Energy - Solar energy for Groundwater pumping
11
15.0
1

MONITOR
1162
522
1253
567
Acc elec cost
acc-elec-cost
17
1
11

MONITOR
1162
621
1253
666
Acc solar cost (GW)
acc-solar-cost_GW
17
1
11

MONITOR
1162
424
1253
469
Total area (ha)
total-area
17
1
11

MONITOR
1162
473
1253
518
Acc fuel cost
acc-fossil-cost
17
1
11

MONITOR
1162
178
1253
223
Net profit
rice-net-income
2
1
11

TEXTBOX
30
14
180
32
100 years, from 2000 to 2099
11
0.0
1

MONITOR
1162
29
1253
74
Rice yield
rice-tot-yield
17
1
11

MONITOR
1162
770
1253
815
Rice income
rice-tot-income
2
1
11

MONITOR
1162
720
1253
765
Yearly rice expenses
rice-expenses
17
1
11

TEXTBOX
1163
11
1241
29
Monitor
12
0.0
1

MONITOR
1162
671
1253
716
Acc energy costs
acc-energy-costs
17
1
11

CHOOSER
249
150
366
195
Crop_seasons
Crop_seasons
"1" "2"
0

TEXTBOX
254
121
404
149
1 = in-season only\n2 = in and off seasons
11
0.0
1

PLOT
837
177
1157
321
Yearly irrigation requirements
Years
m3/ha
0.0
100.0
0.0
20000.0
false
true
"set-plot-background-color 84" ""
PENS
"Rice IWR" 1.0 0 -2674135 true "" "if ticks >= 1\n[ plot rice-irreq ]"

MONITOR
1162
78
1253
123
Irrig. Req.
rice-irreq
17
1
11

INPUTBOX
713
622
828
682
Sol_pump_install_cost_SW
9000.0
1
0
Number

INPUTBOX
711
814
826
874
Sol_pump_install_cost_GW
11000.0
1
0
Number

MONITOR
1162
376
1219
421
Ft
ft
17
1
11

INPUTBOX
318
740
425
800
Elec_maintain_cost
500.0
1
0
Number

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

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

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
NetLogo 6.2.0
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
