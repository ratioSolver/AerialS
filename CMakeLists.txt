cmake_minimum_required(VERSION 3.8)
project(aerials)

if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  add_compile_options(/W4)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/DeliberativeState.msg"
  "msg/Rational.msg"
  "msg/Task.msg"
  "srv/ExecutionService.srv"
  "srv/ReasonerBuilder.srv"
  "srv/ReasonerDestroyer.srv"
  "srv/RequirementManager.srv"
  "srv/TaskCloser.srv"
  "srv/TaskExecutor.srv"
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  set(ament_cmake_copyright_FOUND TRUE)
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
