cmake_minimum_required(VERSION 3.21)
project(omde-logind LANGUAGES CXX)

find_package(Qt6 6.5 REQUIRED COMPONENTS DBus Qml Test)
qt_standard_project_setup(REQUIRES 6.5)
include(GNUInstallDirs)

qt_add_qml_module(omde-logind
	URI OMDE.Logind
	VERSION 1.0
	PLUGIN_TARGET omde-logind
	OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/OMDE/Logind"
	SOURCES logind.cpp logind.hpp
)
target_link_libraries(omde-logind PRIVATE Qt6::DBus Qt6::Qml)

set(module_dir "${CMAKE_INSTALL_LIBDIR}/qt-6/qml/OMDE/Logind")
install(TARGETS omde-logind LIBRARY DESTINATION "${module_dir}")
install(FILES
	"${CMAKE_CURRENT_BINARY_DIR}/OMDE/Logind/qmldir"
	"${CMAKE_CURRENT_BINARY_DIR}/OMDE/Logind/omde-logind.qmltypes"
	DESTINATION "${module_dir}"
)

enable_testing()
qt_add_executable(omde-logind-test
	tests/tst_logind.cpp
	logind.cpp
)
target_include_directories(omde-logind-test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

get_target_property(_qt_qml_lib Qt6::Qml IMPORTED_LOCATION_RELEASE)
if(NOT _qt_qml_lib)
	get_target_property(_qt_qml_lib Qt6::Qml IMPORTED_LOCATION)
endif()
if(_qt_qml_lib)
	get_filename_component(_qt_qml_lib_dir "${_qt_qml_lib}" DIRECTORY)
	set(_qt_qml_import_dir "${_qt_qml_lib_dir}/qt-6/qml")
endif()

target_compile_definitions(omde-logind-test PRIVATE
	OMDE_LOGIND_IMPORT_PATH="${CMAKE_CURRENT_BINARY_DIR}"
	QT_QML_IMPORT_DIR="${_qt_qml_import_dir}"
)
target_link_libraries(omde-logind-test PRIVATE
	Qt6::Core Qt6::DBus Qt6::Qml Qt6::Test
)
add_dependencies(omde-logind-test omde-logind)
add_test(NAME omde-logind-test COMMAND omde-logind-test)
