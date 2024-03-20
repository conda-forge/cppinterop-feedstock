#include "clang/Interpreter/CppInterOp.h"

#include <algorithm>
#include <iostream>
#include <string>

using Args = std::vector<std::string>;

void* createInterpreter(const char* CxxCompiler, const Args &ExtraArgs = {}) {
  Args ClangArgs;
  if (std::find(ExtraArgs.begin(), ExtraArgs.end(), "-resource-dir") != ExtraArgs.end()) {
    std::string resource_dir = Cpp::DetectResourceDir();
    if (resource_dir == "")
      std::cerr << "Failed to detect the resource-dir\n";
    ClangArgs.push_back("-resource-dir");
    ClangArgs.push_back(resource_dir);
  }
  std::vector<std::string> CxxSystemIncludes;
  Cpp::DetectSystemCompilerIncludePaths(CxxSystemIncludes, CxxCompiler);
  for (const std::string &CxxInclude : CxxSystemIncludes) {
    ClangArgs.push_back("-isystem");
    ClangArgs.push_back(CxxInclude);
  }
  ClangArgs.insert(ClangArgs.end(), ExtraArgs.begin(), ExtraArgs.end());
  // FIXME: We should process the kernel input options and conditionally pass
  // the gpu args here.
  std::vector<const char*> Args(ClangArgs.size());

  std::transform(ClangArgs.begin(), ClangArgs.end(), Args.begin(),
                 [](const std::string &s) -> const char * { return s.data(); });

  return Cpp::CreateInterpreter(Args/*, {"-cuda"}*/);
}

int main(int argc, char *argv[]) {
  if (argc < 2)
    std::cerr << "Not enough arguments. Pass a compiler name.\n";

  createInterpreter(argv[1], {"-v"});

  return Cpp::Process("#include <string>");
}
