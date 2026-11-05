#include "CppInterOp/CppInterOp.h"

#include <algorithm>
#include <iostream>
#include <string>
#include <sys/stat.h>

inline bool file_exists(const std::string& name) {
  struct stat buffer;
  return (stat (name.c_str(), &buffer) == 0);
}

inline std::string append_path(const std::string &to, const std::string& what) {
#if defined(WIN32)
#  define DIR_SEPARATOR '\\'
#else
#  define DIR_SEPARATOR '/'
#endif
  return to + DIR_SEPARATOR + what;
}

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
  // Oddly, conda supports "pseudo cross-compilation" and gives us the compiler
  // include paths relative to the compiler binary. Now we need to find out
  // where that binary is...
  const char* Prefix = CONDA_PREFIX;
  Cpp::DetectSystemCompilerIncludePaths(CxxSystemIncludes, CxxCompiler);
  for (std::string CxxInclude : CxxSystemIncludes) {
    if (!file_exists(CxxInclude)) {
      // Try make these paths absolute.
      std::string FullPath = append_path(Prefix, CxxInclude);
      if (!file_exists(FullPath)) {
        std::cerr << "'" << CxxInclude << "'" << " not found, neither is '"
                  << FullPath << "'\n";
        continue;
      }
      CxxInclude = FullPath;
    }
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
  if (argc < 2) {
    std::cerr << "Not enough arguments. Pass a compiler name.\n";
    return 1;
  }

  if (createInterpreter(argv[1], {"-v"}) == nullptr)
    return 1;

  if (Cpp::Process("#include <string>"))
    return 1;

  // Exercise the AST and template interfaces changed by Clang 22/23.
  if (Cpp::Declare("struct BackportRecord {}; "
                   "template<class T> struct BackportBox { T value; }; "
                   "template<class T> constexpr int backport_size = sizeof(T);"))
    return 1;
  auto record = Cpp::GetType("BackportRecord");
  if (!record || Cpp::GetTypeAsString(record) != "BackportRecord" ||
      Cpp::GetCompleteName(Cpp::GetScopeFromType(record)) != "BackportRecord")
    return 1;

  Cpp::TemplateArgInfo arg(Cpp::GetType("int"));
  if (!Cpp::InstantiateTemplate(Cpp::GetNamed("BackportBox"), &arg, 1) ||
      !Cpp::InstantiateTemplate(Cpp::GetNamed("backport_size"), &arg, 1))
    return 1;

  bool had_error = false;
  if (Cpp::Evaluate("6 * 7", &had_error) != 42 || had_error)
    return 1;

  // Silencing diagnostics must preserve the error status and permit recovery.
  if (!Cpp::Declare("invalid_syntax!!!;", true))
    return 1;
  if (Cpp::Declare("int backport_recovered = 42;"))
    return 1;
  return Cpp::Evaluate("backport_recovered", &had_error) == 42 && !had_error
             ? 0 : 1;
}
