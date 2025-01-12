local extractors = require("neogen.utilities.extractors")
local nodes_utils = require("neogen.utilities.nodes")
local template = require("neogen.utilities.template")
local i = require("neogen.types.template").item

return {
    parent = {
        type = { "property_declaration", "const_declaration", "foreach_statement" },
        func = { "function_definition" },
        class = { "class_declaration" },
    },
    data = {
        type = {
            ["property_declaration|const_declaration|foreach_statement"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            { node_type = "property_element", retrieve = "all", extract = true, as = i.Type },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
        func = {
            ["function_definition"] = {
                ["0"] = {
                    extract = function(node)
                        local tree = {
                            {
                                node_type = "formal_parameters",
                                retrieve = "first",
                                subtree = {
                                    {
                                        node_type = "simple_parameter",
                                        retrieve = "all",
                                        subtree = {
                                            {
                                                node_type = "variable_name",
                                                retrieve = "all",
                                                extract = true,
                                                as = i.Parameter,
                                            },
                                        },
                                    },
                                },
                            },
                            {
                                node_type = "compound_statement",
                                retrieve = "first",
                                subtree = {
                                    {
                                        retrieve = "first",
                                        node_type = "return_statement",
                                        recursive = true,
                                        extract = true,
                                        as = i.Return,
                                    },
                                },
                            },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        local res = extractors:extract_from_matched(nodes)
                        return res
                    end,
                },
            },
        },
        class = {
            ["class_declaration"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },
    template = template:add_default_annotation("phpdoc"),
}
