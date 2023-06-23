local styles = data.raw["gui-style"].default

styles["IC2_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    horizontally_stretchable = "on"
}

styles["IC2_interior_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    use_header_filler = false,
    drag_by_title = false
}

styles["IC2_controls_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles["IC2_controls_textfield"] = {
    type = "textbox_style",
    width = 36
}

styles["IC2_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}

styles["IC2_component_bar"] = {
    type = "progressbar_style",
    --bar_width = 50,
    embed_text_in_bar = false
}
styles["IC2_heat_bar"] = {
    type = "progressbar_style",
    horizontal_align = "right",
    vertical_align = "bottom",
    --bar_width = 50,
    embed_text_in_bar = false
}

styles["IC2_reactor_slot_flow"] = {
    type = "vertical_flow_style",
    horizontal_align = "center",
    vertical_spacing = -4
}

data:extend({
    {
        type = "custom-input",
        name = "ugg_toggle_interface",
        key_sequence = "CONTROL + I",
        order = "a"
    }
})
