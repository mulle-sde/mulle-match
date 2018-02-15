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
src/mulle-monitor-callback.sh
src/mulle-monitor-clean.sh
src/mulle-monitor-find.sh
src/mulle-monitor-match.sh
src/mulle-monitor-patternfile.sh
src/mulle-monitor-process.sh
src/mulle-monitor-run.sh
src/mulle-monitor-task.sh
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
