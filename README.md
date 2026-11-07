# Vim Light Kit

C# · Rust · C++ · C · Go · Python · JavaScript를 위한 밝고 간결한 **일반 Vim** 설정입니다.
작성일: 2026-11-08.

기본 구성은 Everforest Light Soft, 소규모 범용 플러그인 6개, Vim 내장 파일 탐색·버퍼 전환·완성·quickfix입니다.
별도 플러그인 관리자는 필요하지 않습니다. Git으로 Vim의 native package 경로에 설치합니다.

## 1. 빠른 설치

ZIP 전체를 풀고 `vimrc`, `plugins.tsv`, 설치 스크립트를 같은 폴더에 둡니다.
설치 시 Git과 GitHub 접속이 필요합니다. 설정을 쓰려면 **full Vim 8.2 이상**이 필요하며 **최근 Vim 9.x**를 권장합니다.
축소판 `vim-tiny`/BusyBox vi, Neovim의 `init.lua`용 설정은 대상이 아닙니다.

### macOS / Linux / WSL / SSH 서버

Vim과 Git이 이미 있으면 설치 명령만 실행합니다.

```sh
cd ~/Downloads/vim-light-kit
sh ./install.sh
vim
```

도구가 필요한 경우에만 OS에 맞게 설치합니다. 설치 스크립트 자체는 패키지 관리자를 실행하지 않습니다.

```sh
# macOS: Homebrew가 이미 설치된 경우
brew install vim git

# Ubuntu / Debian
sudo apt update
sudo apt install vim git
```

WSL과 SSH에서는 **Vim을 실행할 환경 안에서** `install.sh`를 실행합니다.
SSH 서버의 Vim이 사용할 설정은 서버의 사용자 홈에 설치되어야 합니다.

### Windows

Vim과 Git이 없다면 먼저 설치하고 새 터미널을 엽니다.

```powershell
winget install --id Vim.Vim --exact
winget install --id Git.Git --exact
```

압축을 푼 폴더에서 실행합니다.

```powershell
cd "$HOME\Downloads\vim-light-kit"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
vim
```

`-ExecutionPolicy Bypass`는 위 PowerShell 프로세스에만 적용됩니다. 설치기는 실행 정책을 영구 변경하지 않습니다.
PowerShell 7을 쓰고 스크립트 실행이 허용된 환경에서는 `pwsh -NoProfile -File .\install.ps1`도 가능합니다.
Vim이 PATH에 없으면 설치기가 안내합니다. Vim 설치 경로를 PATH에 추가하거나 해당 `vim.exe`/`gvim.exe`를 실행하세요.

### 처음 한 번 확인

설치 전에 열려 있던 Vim은 종료하고 다시 실행합니다. Vim 안에서:

```vim
:LightVimHealth
:helptags ALL
```

`LightVimHealth`는 로드한 설정 경로, 테마, true color, undo, 클립보드, 도구와 플러그인 설치 여부를 보여줍니다.
`helptags ALL`은 플러그인 도움말 색인을 만듭니다. 예: `:help commentary`, `:help surround`, `:help fugitive`.

## 2. 들어 있는 파일

| 파일 | 역할 |
|---|---|
| `vimrc` | 실제 Vimscript 설정 |
| `install.sh` | macOS, Linux, WSL용 POSIX shell 설치기 |
| `install.ps1` | Windows PowerShell 5.1 / PowerShell 7용 설치기 |
| `plugins.tsv` | 두 설치기가 함께 읽는 플러그인 이름·공식 저장소·브랜치 목록 |
| `vimrc.local.example` | 개인 설정 예제. 자동 실행되지 않음 |
| `README-ko.md` | 설치, 단축키, 언어별 사용법, 복구 안내 |

`.ps1`과 `.sh`만 단독 다운로드하지 말고 ZIP 전체를 사용하는 것이 가장 간단합니다.

## 3. 플러그인 6개

| 플러그인 | 사용하는 기능 |
|---|---|
| [vim-commentary](https://github.com/tpope/vim-commentary) | `gcc`로 한 줄, 선택 후 `gc`로 여러 줄 주석 전환 |
| [vim-surround](https://github.com/tpope/vim-surround) | 따옴표·괄호·태그 추가, 변경, 삭제 |
| [vim-repeat](https://github.com/tpope/vim-repeat) | 지원되는 플러그인 편집 동작을 `.`으로 반복 |
| [vim-fugitive](https://github.com/tpope/vim-fugitive) | Vim 안에서 Git 상태·diff·커밋 등의 작업 |
| [vim-sleuth](https://github.com/tpope/vim-sleuth) | 파일 스타일과 `.editorconfig`에 따른 들여쓰기 설정 |
| [everforest](https://github.com/sainnhe/everforest) | 크림색 배경의 Light Soft 테마 |

Sleuth가 `.editorconfig`의 들여쓰기, 줄바꿈, 인코딩 등 지원하는 항목을 읽으므로 별도 EditorConfig 플러그인은 추가하지 않았습니다.
Sleuth는 모든 EditorConfig 속성을 구현하는 도구는 아닙니다. 예를 들어 저장 시 공백 자동 제거 기능을 이 구성에서 제공한다고 가정하면 안 됩니다.

파일 탐색은 내장 netrw, 상태 표시줄은 기본 `statusline`, 버퍼 선택은 `:ls`/`:buffer`를 사용합니다.
특수 아이콘 폰트나 Node/Python 플러그인 호스트는 필요하지 않습니다.
기존에 설치한 다른 Vim 플러그인은 보존되므로, 기존 환경의 전체 자원 사용량은 그 플러그인에도 영향을 받습니다.

## 4. 밝은 테마

기본값은 다음과 같습니다.

```vim
set background=light
let g:everforest_background = 'soft'
let g:everforest_ui_contrast = 'high'
let g:everforest_disable_italic_comment = 1
```

배경은 따뜻한 크림색이며, 줄 번호 등 UI 요소는 읽기 쉬운 대비를 선택했습니다.
주석 기울임은 끄고, 투명 배경도 사용하지 않습니다. 테마 선호와 편안함에는 개인차가 있으므로 화면 밝기도 함께 조절하세요.

24비트 색 지원을 알리는 `COLORTERM`/Windows Terminal 등의 환경에서는 `termguicolors`를 켭니다.
지원 여부를 확인하기 어려운 터미널은 256색 경로를 사용합니다. SSH와 tmux에서는 색 지원 환경 변수가 전달되지 않을 수 있습니다.
실제 터미널이 true color를 지원하는데 색이 다르면 `~/.vimrc.local`에 다음을 추가합니다.

```vim
if has('termguicolors')
  set termguicolors
endif
```

제한된 터미널에서 색이 깨지면 `set notermguicolors`를 사용합니다. 터미널 앱 자체의 테마는 별도로 밝게 설정하면 됩니다.

Everforest의 성능 옵션은 구문 강조 파일을 생성해 지연 로드하므로 최초 실행이 이후 실행보다 느릴 수 있습니다.
플러그인을 받지 않은 상태에서도 크림색의 자체 fallback 강조 설정으로 실행됩니다.

## 5. 기본 단축키

`Space b`는 스페이스를 누른 뒤 `b`를 누르는 뜻입니다. 아래 항목은 별도 표시가 없으면 Normal 모드 기준입니다.

| 키 | 동작 |
|---|---|
| `Space w` | 변경한 파일 저장 |
| `Space e` | 왼쪽 파일 탐색기 열기/닫기 |
| `Space f` | 파일 경로 입력, Tab으로 완성 |
| `Space b` | 버퍼 목록 표시 후 번호/이름으로 선택 |
| `[b` / `]b` | 버퍼 목록의 이전 / 다음 파일 |
| `Ctrl+6` 또는 `Space Space` | 직전에 편집한 버퍼로 전환 |
| `Space d` | 현재 버퍼 닫기. 저장하지 않은 변경이 있으면 Vim이 막음 |
| `Space v` / `Space s` | 세로 / 가로 분할 |
| `Ctrl+h/j/k/l` | 왼쪽 / 아래 / 위 / 오른쪽 창 이동 |
| `Space q` | 현재 분할 창 닫기 |
| `Space h` | 검색 강조 지우기 |
| `Space /` | `:grep` 입력 시작 |
| `Space co` / `Space cc` | quickfix 열기 / 닫기 |
| `[q` / `]q` | quickfix의 이전 / 다음 결과 |
| `Space gs` | Git 상태 |
| `Space gd` | 현재 파일의 Git diff 분할 |
| `Space rn` | 상대 줄 번호 켜기/끄기 |
| `Space tw` | 화면 줄바꿈 켜기/끄기 |
| `Space tl` | 탭·후행 공백 표시 켜기/끄기 |
| 선택 후 `<` / `>` | 들여쓰기 변경 후 선택 유지 |
| `Space y` / `Space p` | 시스템 클립보드 복사 / 붙여넣기. `+clipboard` 빌드에서만 설정됨 |

`[b`/`]b`는 **버퍼 목록 순서**이고, `Ctrl+6`/`Space Space`는 **현재 버퍼와 직전 버퍼 왕복**입니다.
마우스는 기본적으로 끄므로 터미널 자체의 드래그 선택을 사용할 수 있습니다. Vim 마우스 조작이 필요하면 개인 설정에 `set mouse=a`를 추가하세요.

### 주석과 괄호 편집

| 입력 | 예 |
|---|---|
| `gcc` | 현재 줄의 주석 전환 |
| Visual 선택 후 `gc` | 선택 범위의 주석 전환 |
| `ysiw"` | 현재 단어를 큰따옴표로 감싸기 |
| `cs"'` | 큰따옴표를 작은따옴표로 변경 |
| `ds"` | 감싼 큰따옴표 제거 |
| `.` | 지원되는 직전 편집 반복 |

## 6. 언어별 지원 범위

| 언어 | Vim filetype | 프로젝트 규칙이 없을 때의 기본 들여쓰기 |
|---|---|---|
| C# | `cs` | 공백 4칸 |
| Rust | `rust` | 공백 4칸 |
| C++ | `cpp` | 공백 4칸 |
| C | `c` | 공백 4칸 |
| Go | `go` | 실제 탭, 표시 폭 8칸 |
| Python | `python` | 공백 4칸 |
| JavaScript | `javascript` | 공백 2칸 |

C/C++ 등의 들여쓰기 폭은 이 설정의 기본 선호값입니다. 파일 내용의 들여쓰기나 `.editorconfig`가 있으면 Sleuth가 반영합니다.
`tabstop=8`과 `shiftwidth=4`는 서로 다릅니다. 공백 언어에서 Tab을 누를 때 적용되는 들여쓰기 폭은 `softtabstop=-1`을 통해 `shiftwidth`를 따릅니다.

구문 강조와 들여쓰기는 Vim runtime을 사용합니다. 최신 언어 문법 지원은 설치한 Vim runtime 버전에 따라 차이가 있습니다.
실시간 타입 분석, 프로젝트 전체 의미 기반 rename, C# IntelliSense, rust-analyzer 진단은 이 기본 구성의 범위에 포함되지 않습니다.
이런 기능이 필요할 때 사용하는 언어의 LSP만 추가하는 것이 자원 사용을 조절하기 좋습니다.

### 내장 완성

Insert 모드에서:

| 키 | 기능 |
|---|---|
| `Ctrl+n` / `Ctrl+p` | 현재/열린 버퍼 및 tags의 단어 후보 |
| `Ctrl+x Ctrl+f` | 파일 경로 완성 |
| `Ctrl+x Ctrl+l` | 줄 단위 완성 |

이 완성은 텍스트와 태그를 이용합니다. 타입 검사에 기반한 자동완성과는 기능 범위가 다릅니다.

### 정의 위치 이동: 선택 사항인 Universal Ctags

별도로 [Universal Ctags](https://ctags.io/)를 설치하고 프로젝트 루트에서 필요할 때 색인을 만듭니다.
macOS에 기본 제공되는 다른 `ctags` 구현과 구별하세요.

```sh
ctags -R --exclude=.git --exclude=node_modules --exclude=target --exclude=bin --exclude=obj --exclude=build .
```

그다음 Vim에서 `Ctrl+]`로 태그 정의 위치에 이동하고 `Ctrl+t`로 돌아옵니다.
이 설정의 `tags=./tags;,tags`는 현재 파일의 상위 디렉터리에서도 `tags`를 찾습니다.
색인은 자동 갱신되지 않으며, 태그 탐색은 컴파일러의 의미 분석과 동일하지 않습니다.

## 7. 프로젝트 검색과 빌드

### ripgrep으로 검색

별도로 [ripgrep](https://github.com/BurntSushi/ripgrep#installation)을 설치하면 다음 Vim 실행부터 `:grep`에 사용합니다.
macOS Homebrew에서는 `brew install ripgrep`, Ubuntu/Debian에서는 `sudo apt install ripgrep`으로 설치할 수 있습니다.

프로젝트 루트에서 Vim을 실행하고 다음과 같이 검색합니다.

```vim
:grep MyFunction .
```

결과는 quickfix 창으로 표시됩니다. `]q`, `[q`로 이동합니다. 패턴에 공백이나 셸 특수문자가 있으면 사용하는 셸의 규칙에 맞게 따옴표를 붙입니다.
기본 ripgrep 검색은 `.gitignore`를 따르며, 이 설정은 `node_modules`, `target`, `bin`, `obj`, `build`, `dist`도 제외합니다.
이름에 해당하는 소스 폴더까지 검색하려면 `:set grepprg=rg\ --vimgrep\ --smart-case\ --`로 추가 제외 규칙을 제거할 수 있습니다.

ripgrep이 없으면 Vim의 기존 `grepprg`를 유지합니다. Windows에서 외부 grep도 없다면 Vim 내장 검색을 사용할 수 있습니다.

```vim
:vimgrep /MyFunction/j src/**/*.c
```

### 명시적으로 실행하는 빌드

빌드, lint, formatter는 저장 시 자동 실행하지 않습니다. 프로젝트 루트에서 Vim을 실행한 뒤 필요한 compiler 설정을 고릅니다.
언어 도구는 따로 설치되어 있어야 합니다.

| 언어/도구 | Vim 명령 |
|---|---|
| Rust / Cargo | `:compiler cargo` → `:make check` |
| Go | `:compiler go` → `:make ./...` |
| C# / .NET | `:compiler dotnet` → `:make` |
| C/C++ / Make | `:compiler gcc` → `:setlocal makeprg=make` → `:make` |

Vim compiler 파일은 `makeprg`와 오류 파싱 규칙을 연결합니다. `go`는 `go build`, `dotnet`은 `dotnet build`가 이미 포함되므로 `:make build`를 중복 입력하지 않습니다.
구형 Vim에 특정 compiler 파일이 없으면 최신 Vim으로 업데이트하거나 프로젝트에 맞게 `makeprg`/`errorformat`을 지정합니다.
`:make`는 동기식입니다. 긴 빌드는 별도 터미널에서 실행하면 편합니다.
Python/JavaScript의 테스트·검사·formatter도 프로젝트가 사용하는 도구를 터미널에서 실행하면 됩니다.

## 8. 설치·업데이트·백업 동작

### 옵션

| 목적 | shell | PowerShell |
|---|---|---|
| 기본 설치 | `sh install.sh` | `.\install.ps1` |
| Git 다운로드 없이 설정만 설치 | `sh install.sh --no-plugins` | `.\install.ps1 -NoPlugins` |
| 플러그인 업데이트 | `sh install.sh --update` | `.\install.ps1 -Update` |
| 다른 사용자 홈 경로 지정 | `sh install.sh --target-home /path/to/home` | `.\install.ps1 -TargetHome 'C:\path\to\home'` |

`--no-plugins`/`-NoPlugins`는 기존 플러그인을 삭제하거나 비활성화하는 옵션이 아닙니다.
현재 설치된 플러그인은 그대로 사용할 수 있으며, 신규 환경에서는 밝은 fallback 설정을 사용합니다.
`--no-plugins`와 `--update`는 함께 사용할 수 없습니다.

`--target-home`은 설치 위치를 고르는 옵션입니다. 그 설정을 사용할 Vim도 같은 사용자 홈을 사용해야 합니다.
설정만 `vim -u 다른경로/vimrc`로 열면 Vim의 기본 HOME/package 경로까지 자동으로 바뀌지는 않습니다.

### 경로

| 항목 | macOS / Linux / WSL | Windows |
|---|---|---|
| 기본 설정 | `~/.vimrc` | 기본 `~/_vimrc` |
| 플러그인 | `~/.vim/pack/lightvim/start/` | `~/vimfiles/pack/lightvim/start/` |
| undo·swap·임시 저장 백업 | `~/.vim/lightvim-state/` | `~/vimfiles/lightvim-state/` |
| 설치 전 백업 | `~/.vim/lightvim-backups/` | `~/vimfiles/lightvim-backups/` |
| 개인 설정 | `~/.vimrc.local` | `~/.vimrc.local` |

Windows에서는 기존 `_vimrc`를 먼저 사용합니다. `_vimrc`가 없고 `.vimrc`만 있으면 그 파일을 사용합니다.
둘 다 있을 때는 Vim의 읽기 순서에 맞춰 `_vimrc`만 교체하고 `.vimrc`는 보존합니다.

설정 내용이 동일한 재실행에서는 불필요한 백업을 만들지 않습니다.
교체하는 기존 설정은 날짜와 고유 접미사를 붙인 백업 폴더의 `vimrc.previous`로 보존합니다.
설정이 심볼릭 링크이면 링크 대상 파일에 덮어쓰지 않고 링크 자체를 백업합니다.
개인 설정 `.vimrc.local`과 다른 플러그인 경로는 수정하지 않습니다.

신규 플러그인은 공식 GitHub 저장소의 지정 브랜치를 shallow clone합니다.
설치 시점의 브랜치 HEAD를 받으므로 버전이 영구 고정된 묶음은 아닙니다.
실제 설치 커밋은 Vim 디렉터리의 `lightvim-plugin-revisions.tsv`에 기록합니다.

기본 재실행은 이미 있는 플러그인을 유지합니다. 업데이트를 명시한 경우 원격 주소, 브랜치, 추적 파일의 변경 여부를 확인하고 임시 복사본에서 fast-forward 업데이트를 준비합니다.
다운로드·pull이 실패하면 기존 활성 설정과 플러그인을 유지합니다.
업데이트로 바뀌는 이전 플러그인 디렉터리는 해당 실행의 백업 폴더 `plugins/`에 보존합니다.
Everforest가 생성한 추적되지 않는 캐시 파일도 복사해 유지합니다.

### 이전 설정 복구

Vim을 닫고 설치 완료 시 출력된 **Restore previous config** 또는 **To restore the previous vimrc** 명령을 실행하세요.
백업 파일은 위 경로의 `vimrc.previous`입니다.
설정 파일만 되돌려도 native `pack/*/start`에 설치된 플러그인은 계속 로드됩니다.
이 키트의 플러그인도 함께 비활성화하려면 `pack/lightvim` 디렉터리를 `pack` 바깥의 보관 위치로 옮깁니다.
다른 플러그인 디렉터리는 그대로 두세요.

## 9. 개인 설정과 큰 파일

설치기는 `~/.vimrc.local.example`을 한 번 복사합니다. 필요한 내용을 `~/.vimrc.local`에 옮겨 편집하면 다음 설치 때도 보존됩니다.
예제 전체를 사용하려면:

```sh
# 기존 .vimrc.local이 없는 경우에만
cp ~/.vimrc.local.example ~/.vimrc.local
```

기본적으로 2 MiB를 초과하는 파일은 구문 강조를 끄고 Sleuth의 들여쓰기 추측을 줄입니다.
긴 줄의 구문 강조는 `synmaxcol=240`으로 제한합니다. 파일 내용 자체를 자르거나 수정하지 않습니다.
큰 디컴파일 결과나 로그에서도 편집 부담을 줄이기 위한 설정이며, 파일 읽기 자체의 메모리 사용까지 제한하는 것은 아닙니다.

```vim
" ~/.vimrc.local: 구문 강조 차단 기준을 8 MiB로 변경
let g:lightvim_large_file_bytes = 8 * 1024 * 1024

" 긴 줄에서 더 멀리 구문 강조
set synmaxcol=500
```

이미 큰 파일로 판정된 버퍼는 기준을 바꾼 뒤 다시 열면 됩니다.
설정이 적용되지 않으면 `:echo $MYVIMRC`, `:scriptnames`, `:messages`로 읽은 파일과 오류를 확인합니다.
`VIMINIT` 또는 `vim -u ...`는 기본 설정 파일 선택을 바꿀 수 있습니다.

## 10. 검증 범위

2026-11-08에 다음을 확인했습니다.

| 대상 | 확인 결과 |
|---|---|
| Vim 9.2.1302, Linux | 기본 시작 시 설정 자동 로드, 공식 플러그인 6개 설치 및 로드, 시작 오류 없음 |
| 7개 언어 | 파일타입, 구문 강조, 들여쓰기 기본값 확인 |
| 프로젝트 규칙 | Python `.editorconfig`의 2칸 들여쓰기가 기본 4칸을 덮어쓰는 동작 확인 |
| 테마·편집 | Everforest light/soft, Commentary·Surround 실제 편집, Repeat 로드, Fugitive 명령 확인 |
| 버퍼·undo | `[b`/`]b`/`Ctrl+6` 실제 전환, Vim 재실행 후 persistent undo 복원 확인 |
| 큰 파일 | 2,400,025바이트 파일에서 syntax 제한 및 Sleuth 자동 추측 제한 확인 |
| shell 설치기 | 구문 검사, 최초 설치, 재실행, 백업/복구, 심볼릭 링크, 공백·한글·작은따옴표 경로 확인 |
| 플러그인 업데이트 | 로컬 Git 저장소로 clone/update/이전 버전 백업/캐시 유지/다운로드 도중 실패/수정된 저장소 보호 확인 |
| PowerShell 7.6.9, Linux | 파싱, 설치·재실행·백업·심볼릭 링크·Git clone/update/실패 보존 확인 |
| Windows 파일명 선택 | `_vimrc`/`.vimrc`의 존재 조합 4가지를 선택 로직으로 확인 |

실제 Windows/macOS, Windows PowerShell 5.1, Vim 8.2에서 실행한 결과는 아닙니다.
PowerShell 스크립트는 5.1 호환 문법으로 작성했으며 Linux의 PowerShell 7에서 실행 검증했습니다.
클립보드·GUI·실제 언어 컴파일러 실행·주관적인 화면 편안함은 이 검증에 포함되지 않습니다.
고정된 시작 시간이나 메모리 사용량은 보장하지 않습니다.

## 11. 공식 참고 문서

- [Vim 다운로드 및 현재 지원 빌드](https://www.vim.org/download.php)
- [Vim native packages](https://vimhelp.org/repeat.txt.html#packages)
- [Vim 설정 파일 로드 순서](https://vimhelp.org/starting.txt.html#initialization)
- [Vim 내장 완성](https://vimhelp.org/insert.txt.html#ins-completion)
- [Everforest 설정](https://github.com/sainnhe/everforest/blob/master/doc/everforest.txt)
- [Sleuth와 EditorConfig](https://github.com/tpope/vim-sleuth)
- [Homebrew Vim](https://formulae.brew.sh/formula/vim)
- [Git Windows 설치](https://git-scm.com/install/windows)
- [ripgrep 설치](https://github.com/BurntSushi/ripgrep#installation)
- [Universal Ctags](https://ctags.io/)

외부 플러그인 코드는 ZIP에 포함하지 않으며 설치 때 공식 저장소에서 받습니다. 각 플러그인의 라이선스는 해당 저장소를 따릅니다.
