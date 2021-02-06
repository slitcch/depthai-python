# Helper to create a pybind11_mkdoc target which takes
include(target-public-headers)

# Usage:
# target_pybind11_mkdoc_setup([path/to/output/docstring.hpp] [Library for which to generate: target-name] [Enforce pybind11_mkdoc existing ON/OFF])
function(target_pybind11_mkdoc_setup output_file target enforce)

    # gets target public headers
    get_target_public_headers(${target} header_files)

    # Setup mkdoc target
    pybind11_mkdoc_setup_internal("${target}" "${output_file}" "${header_files}" ${enforce})

endfunction()

# Internal helper, sets up pybind11_mkdoc target
function(pybind11_mkdoc_setup_internal target output_path mkdoc_headers enforce)

    # constants
    set(PYBIND11_MKDOC_MODULE_NAME "pybind11_mkdoc")
    set(PYBIND11_MKDOC_TARGET_NAME "pybind11_mkdoc")

    # Execute module pybind11_mkdoc to check if present
    execute_process(COMMAND ${PYTHON_EXECUTABLE} -m ${PYBIND11_MKDOC_MODULE_NAME} RESULT_VARIABLE error OUTPUT_QUIET)
    if(error)
        set(messageStatus "STATUS")
        if(enforce)
            set(messageStatus "FATAL_ERROR")
        endif()
        message(${messageStatus} "pybind11_mkdoc: Module ${PYBIND11_MKDOC_MODULE_NAME} not found! Target '${PYBIND11_MKDOC_TARGET_NAME}' not available, no docstrings will be generated")
        # Exit
        return()
    endif()

    # Prepare the output folder for the mkdoc
    get_filename_component(output_directory "${output_path}" DIRECTORY)
    # Create the command
    add_custom_command(
        OUTPUT "${output_path}"
        # Create directory first (if it doesn't exist)
        COMMAND ${CMAKE_COMMAND} -E make_directory "${output_directory}"
        # Execute mkdoc
        COMMAND
            ${PYTHON_EXECUTABLE}
            -m ${PYBIND11_MKDOC_MODULE_NAME}
            -o "${output_path}"
            # List of include directories
            "-I$<JOIN:$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,;-I>"
            # List of compiler definitions
            "-D$<JOIN:$<TARGET_PROPERTY:${target},COMPILE_DEFINITIONS>,;-D>"
            # List of headers for which to generate docstrings
            "${mkdoc_headers}"
            # Redirect stderr to not spam output
            2> /dev/null
        DEPENDS ${target}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Creating docstrings with ${PYTHON_EXECUTABLE} -m ${PYBIND11_MKDOC_MODULE_NAME} ..."
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    # Create a target
    add_custom_target(
        ${PYBIND11_MKDOC_TARGET_NAME}
        DEPENDS "${output_path}"
    )

    # Add dependency to mkdoc target (makes sure that mkdoc is executed, and docstrings available)
    add_dependencies(${TARGET_NAME} ${PYBIND11_MKDOC_TARGET_NAME})

endfunction()
