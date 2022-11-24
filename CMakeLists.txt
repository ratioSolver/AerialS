cmake_minimum_required(VERSION 3.8)
project(aerials)

if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  add_compile_options(/W4)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(catkin REQUIRED COMPONENTS message_generation)

add_message_files(FILES
  "DeliberativeState.msg"
  "Rational.msg"
  "Task.msg"
)

add_service_files(FILES
  "Executor.srv"
  "ReasonerBuilder.srv"
  "ReasonerDestroyer.srv"
  "RequirementManager.srv"
  "TaskDelayer.srv"
  "TaskCloser.srv"
  "TaskExecutor.srv"
)

generate_messages()

catkin_package(CATKIN_DEPENDS message_runtime)