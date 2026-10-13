Rifle spec JSON (all keys optional; metres; +X muzzle). Output ONLY this JSON.
receiver{style:ak_stamped|modern_slab|smg_boxy|bullpup_shell, length,width,rail(bullpup)}
grip{style:ak_slanted|raked_poly|vertical|none, length,rake(rad)}  trigger_guard:bool
magazine{style:curved|straight_box|drum, capacity, curve_deg, cant_deg, width, depth}
stock{style:fixed_wood|fixed_poly|folding_wire|folding_strut|bullpup_integral|none, length, folded:bool}
handguard{style:wood_ak|rail_quad|slim_poly|ribbed_shroud|none, length, material:furniture|body (slim_poly)}
barrel{length,radius,profile:plain|tapered|heavy|shrouded, muzzle:brake|flash_hider|suppressor|none, suppressor_length}
gas_tube:bool   sights{front:post|hooded|none, rear:tangent|notch|carry_handle|red_dot|none}
accents[receiver_side|receiver_top|handguard_side|magazine_window|stock_side|barrel_ring]  (glow strips)
palette{body,furniture,barrel,mag,accent,glow,dark: "#hex" | {color,metal,rough,emit}}
