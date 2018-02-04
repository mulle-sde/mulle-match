cmake_minimum_required( VERSION 3.0)

project( mulle-monitor NONE)

execute_process( COMMAND ./mulle-monitor version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_MONITOR_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_MONITOR_VERSION is ${MULLE_MONITOR_VERSION} according to mulle-monitor")


set( PROJECT_VERSION "${MULLE_MONITOR_VERSION}")


set( SCRIPTS
mulle-monitor
)

set( LIBRARY_SCRIPTS
mulle-monitor-match.sh
mulle-monitor-process.sh
mulle-monitor-run.s
)


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-monitor")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
