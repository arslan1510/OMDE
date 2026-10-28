cmake_minimum_required(VERSION 3.21)
project(omde-search LANGUAGES CXX)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Qml Test)
find_package(Threads REQUIRED)
qt_standard_project_setup(REQUIRES 6.5)
include(GNUInstallDirs)

if(OMDE_SEARCH_CORE_LIB)
	add_library(omde-search-core STATIC IMPORTED GLOBAL)
	set_target_properties(omde-search-core PROPERTIES
		IMPORTED_LOCATION "${OMDE_SEARCH_CORE_LIB}"
	)
else()
	find_program(CARGO_EXECUTABLE cargo REQUIRED)
	set(cargo_target_dir "${CMAKE_CURRENT_BINARY_DIR}/cargo")
	set(core_lib "${cargo_target_dir}/release/libomde_search_core.a")
	add_custom_command(
		OUTPUT "${core_lib}"
		COMMAND "${CMAKE_COMMAND}" -E env
			"CARGO_HOME=${CMAKE_CURRENT_BINARY_DIR}/cargo-home"
			"CARGO_TARGET_DIR=${cargo_target_dir}"
			"${CARGO_EXECUTABLE}" build --release --locked
			--manifest-path "${CMAKE_CURRENT_SOURCE_DIR}/core/Cargo.toml"
		DEPENDS
			core/Cargo.toml
			core/Cargo.lock
			core/src/lib.rs
		COMMENT "Building the Rust search core"
		VERBATIM
	)
	add_custom_target(omde-search-core-build DEPENDS "${core_lib}")
	add_library(omde-search-core STATIC IMPORTED GLOBAL)
	set_target_properties(omde-search-core PROPERTIES IMPORTED_LOCATION "${core_lib}")
endif()

set(omde_search_sources
	searchcore.h
	searchindex.cpp
	searchindex.hpp
)

qt_add_qml_module(omde-search
	URI OMDE.Search
	VERSION 1.0
	PLUGIN_TARGET omde-search
	OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/OMDE/Search"
	SOURCES ${omde_search_sources}
)
target_link_libraries(omde-search PRIVATE
	Qt6::Core Qt6::Qml
	omde-search-core Threads::Threads ${CMAKE_DL_LIBS} m
)

set(module_dir "${CMAKE_INSTALL_LIBDIR}/qt-6/qml/OMDE/Search")
install(TARGETS omde-search LIBRARY DESTINATION "${module_dir}")
install(FILES
	"${CMAKE_CURRENT_BINARY_DIR}/OMDE/Search/qmldir"
	"${CMAKE_CURRENT_BINARY_DIR}/OMDE/Search/omde-search.qmltypes"
	DESTINATION "${module_dir}"
)

enable_testing()
qt_add_executable(omde-search-test
	tests/tst_search.cpp
	${omde_search_sources}
)
target_include_directories(omde-search-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

get_target_property(_qt_qml_lib Qt6::Qml IMPORTED_LOCATION_RELEASE)
if(NOT _qt_qml_lib)
	get_target_property(_qt_qml_lib Qt6::Qml IMPORTED_LOCATION)
endif()
if(_qt_qml_lib)
	get_filename_component(_qt_qml_lib_dir "${_qt_qml_lib}" DIRECTORY)
	set(_qt_qml_import_dir "${_qt_qml_lib_dir}/qt-6/qml")
endif()

target_compile_definitions(omde-search-test PRIVATE
	OMDE_SEARCH_IMPORT_PATH="${CMAKE_CURRENT_BINARY_DIR}"
	QT_QML_IMPORT_DIR="${_qt_qml_import_dir}"
)
target_link_libraries(omde-search-test PRIVATE
	Qt6::Core Qt6::Qml Qt6::Test
	omde-search-core Threads::Threads ${CMAKE_DL_LIBS} m
)
if(TARGET omde-search-core-build)
	add_dependencies(omde-search omde-search-core-build)
	add_dependencies(omde-search-test omde-search-core-build)
endif()
add_dependencies(omde-search-test omde-search)
add_test(NAME omde-search-test COMMAND omde-search-test)
