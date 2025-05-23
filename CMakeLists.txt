cmake_minimum_required( VERSION 3.15)

project( mulle-match VERSION 2.2.2 LANGUAGES NONE)

execute_process( COMMAND ./mulle-match version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_MATCH_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_MATCH_VERSION is ${MULLE_MATCH_VERSION} according to mulle-match")


set( PROJECT_VERSION "${MULLE_MATCH_VERSION}")


set( SCRIPTS
mulle-match
mulle-match-to-cmake
mulle-match-to-c
)

file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
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
DESTINATION "libexec/mulle-match")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
