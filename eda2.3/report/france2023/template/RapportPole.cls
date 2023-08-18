% Modèle de rapport pour le pôle
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{template/RapportPole}[2020/11/16 v.0.1 Modèle de rapport du pôle]

% Option éventuelle à déclarer ici
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{report}}
\ProcessOptions \relax
\LoadClass[a4paper]{report}

\RequirePackage{graphicx}
\RequirePackage{tikz}
\usetikzlibrary{calc}

% -----------Police----------- %
%% Colors
\RequirePackage{xcolor}
\definecolor{VertOFB}{RGB}{125,189,89}

%% Fonts
\RequirePackage{fontspec}
\setmainfont[Ligatures=TeX]{Marianne-Regular}
\RequirePackage{newunicodechar} %résoud le pb du NON-BREAKING HYPHEN non présent dans Marianne
\newunicodechar{^^^^2011}{-}

%% Langue
\RequirePackage{polyglossia}
\setmainlanguage{french}

% -----------Page------------- %
%% Page layout
\RequirePackage[a4paper]{geometry}

\newgeometry{top=12.5mm,left=25mm,right=25mm,bottom=12.5mm}
\savegeometry{PremierePage}

\newgeometry{top=12.5mm,left=25mm,right=25mm,bottom=12.5mm}
\savegeometry{PageStandard}

\newgeometry{top=100mm,left=5mm,right=5mm,bottom=20mm}
\savegeometry{DernierePage}

%% nouvelle page en standard
\newcommand{\PageSuivanteStandard}{%
  \newpage\loadgeometry{PageStandard}%
  \fontsize{12pt}{15pt}\selectfont
}
  
%% Derniere page
\newcommand{\PageDerniere}{%
  \newpage\loadgeometry{DernierePage}%
  \fontsize{12pt}{15pt}\selectfont 
     
 %% Logo RF
      \begin{tikzpicture}[remember picture, overlay]%
        \node [shift={(1cm, -1cm)}] at (current page.north west)% permet de
        % fixer les logos sur la page
          [anchor=north west]{
            \includegraphics[height=4cm]{template/img/Republique_Francaise_RVB.png}
            };      
      \end{tikzpicture}
 
 \vspace{12cm}
  Avec le soutien financier de

  %% 4 logos
      \begin{tikzpicture}[remember picture, overlay]%
        \node [shift={(0.50cm, 3.1cm)}] at (current page.south west)% permet de
        % fixer les logos sur la page
          [anchor=south west]{
            \includegraphics[height=2.60cm]{template/img/bandeau_4logos.png}
            };      
      \end{tikzpicture}
      
  \vfill 
  {\fontsize{12}{15}\selectfont 
  \url{www.ofb.gouv.fr}
  \hspace{0.7cm}\url{www.inrae.fr}
  \hspace{0.7cm}\url{www.institut-agro-rennes-angers.fr}
  \hspace{0.7cm}\url{www.univ-pau.fr}
  }
  
}

%% Espacement entre paragraphe
\setlength{\parskip}{1ex plus 0.5ex minus 0.2ex}

% ----------Variables--------- %
\newcommand*{\subtitle}[1]{\gdef\@subtitle{#1}%
}
\newcommand*{\@subtitle}{}

\newcommand*{\reportType}[1]{\gdef\@reportType{#1}%
}
\newcommand*{\@reportType}{}

\RequirePackage{datetime}
\newdateformat{formatageDate}{\monthnamefrench \space \THEYEAR}

% Gestion des affiliations
\RequirePackage{authblk}
\renewcommand*{\Authsep}{\newline}
\renewcommand*{\Authand}{\newline}
\renewcommand*{\Authands}{\newline}

\renewcommand\Authfont{\color{VertOFB}\bfseries\Large}
\renewcommand\Affilfont{\color{black}\bfseries\normalsize}

\newcommand{\affilPole}{Pôle Gestion des Migrateurs Amphihalins dans leur
Environnement, OFB, INRAE, Institut Agro, UNIV PAU \& PAYS ADOUR/E2S UPPA}

% -------maketitle------------ %
\renewcommand*{\maketitle}{%
  \begin{titlepage}
%  \fontspec{Arial}
%% Bandeau à gauche
    \loadgeometry{PremierePage}
      \begin{tikzpicture}[remember picture, overlay] %
        \node [shift={(2.25cm, -2.85cm)}] at (current page.north west) % permet de fixer le bandeau sur la page
          [anchor=north
          west]{\includegraphics[width=2.491cm,height=24.599cm]{template/img/bandeau_gauche.png}};
      \end{tikzpicture}
      
%% Bandeau des logos
      \begin{tikzpicture}[remember picture, overlay]%
        \node [shift={(1cm, -0.8cm)}] at (current page.north west)% permet de
        % fixer les logos sur la page
          [anchor=north west]{
            \includegraphics[height=2.50cm]{template/img/4logos+RF.png}
           };      
      \end{tikzpicture}
      
%% Logo SMAB
\begin{tikzpicture}[remember picture, overlay]%
  \node [shift={(-2cm, 2cm)}] at (current page.south east)% permet de
  % fixer les logos sur la page (x, y)
    [anchor=south east]{
      \includegraphics[height=2.50cm]{template/img/SMAB.jpg}
     };      
\end{tikzpicture}
    
%% Titre
    \vspace{2.7cm}{
      \hspace{5.5cm}{
        \begin{minipage}{100mm}%
          \color{VertOFB}\textbf{\huge\textsc{\@title}}%
        \end{minipage}\unskip\strut\par
      }
    }

%% Sous-titre
    \vspace{3.6cm}{
      \hspace{5.5cm}{
        \begin{minipage}{100mm}%
          \color{VertOFB}\textbf{\LARGE\itshape\@subtitle}%
        \end{minipage}\unskip\strut\par
      }
    }

%% Type de rapport
    \vfill
      \hspace{5.5cm}{
        \begin{minipage}{100mm}%
          \textbf{\large\itshape Rapport \@reportType}%
        \end{minipage}\unskip\strut\par
      }

%% Auteurs
    \vfill
      \hspace{5.5cm}{
        \begin{minipage}{100mm}%
          \@author%
        \end{minipage}\unskip\strut\par
      }
    \vfill

%% Date
      \hspace{5.5cm}{
        \begin{minipage}{100mm}%
          \color{VertOFB}\bfseries\large \formatageDate \@date%
        \end{minipage}\unskip\strut\par
      }
    \vspace{3.6cm}

%% fin page
  \end{titlepage}
}

% -------Titre infra------------- %
\RequirePackage{etoolbox}

%\makeatletter
%\patchcmd{\section}{-3.5ex \@plus -1ex \@minus -.2ex}{-3.5ex \@plus -1ex \@minus -.2ex\setlength{\leftskip}{5cm}}{}{}
%\patchcmd{\subsection}{-3.25ex\@plus -1ex \@minus -.2ex}{3.25ex\@plus -1ex \@minus -.2ex\setlength{\leftskip}{0cm}}{}{}
%\patchcmd{\subsection}{1.5ex \@plus .2ex}{1.5ex \@plus .2ex\setlength{\leftskip}{2cm}}{}{}
%\makeatother

\RequirePackage{titlesec}

%% chapitre
\renewcommand{\thechapter}{\Roman{chapter}}
\titleformat{\chapter}%
  [hang]% style du titre (hang, display, runin, leftmargin, drop, wrap)
  {\bfseries\color{VertOFB}}% changement de fonte commun
  % au numéro et au titre
  {\huge\thechapter.}% spécification du numéro
  {1em}% espace entre le numéro et le titre
  {\Huge}% changement de fonte du titre

\titlespacing{\chapter}{0em}{0em}{2em}
\titleclass{\chapter}{top} % permet de changer le positionnement du titre (page, top, straight)

%% section
\titleformat{\section}%
  [hang]% style du titre (hang, display, runin, leftmargin,
% drop, wrap)
  {\Large\itshape}% changement de fonte commun au numéro et au titre
  {\thesection.}% spécification du numéro
  {1em}% espace entre le numéro et le titre
  {}% changement de fonte du titre
  
\titlespacing{\section}{3em}{2em}{1em}  

%% subsection
\titleformat{\subsection}%
  [hang]% style du titre (hang, display, runin, leftmargin,
% drop, wrap)
  {\Large}% changement de fonte commun au numéro et au titre
  {\thesubsection.}% spécification du numéro
  {1em}% espace entre le numéro et le titre
  {}% changement de fonte du titre

\titlespacing{\subsection}{6em}{1em}{1em}

%% décaler les paragraphes https://tex.stackexchange.com/questions/447894/titlesec-and-leftskip
\let\svpart\part
\let\svchapter\chapter
\let\svsection\section
\let\svsubsection\subsection
\def\part{\leftskip 0em\svpart}
\def\chapter{\leftskip 0em\svchapter}
\def\section{\leftskip 3em\svsection}
\def\subsection{\leftskip 6em\svsubsection}

% -------Figure et Table------------- %
\RequirePackage[labelsep = quad,
singlelinecheck = false, font = it, labelfont = bf,
width = \textwidth, margin={0mm,0mm}, format = hang]{caption}

% figure
\renewcommand{\thefigure}{\Roman{chapter}.\arabic{figure}.}
\captionsetup[figure]{name = Figure}

% table
\RequirePackage{makecell} %pour les tableaux
\renewcommand{\thetable}{\Roman{chapter}.\arabic{table}.}
\captionsetup[table]{name = Tableau}

% -------Sommaire------------- %
\addto\captionsfrench{\renewcommand{\contentsname}{Sommaire}}

%https://tex.stackexchange.com/questions/470090/table-of-contents-spacing-indentation
\RequirePackage{tocloft}
\renewcommand*{\cftchapnumwidth}{2.5em} % règle l'espacement pour le numéro de
% chapitre
\renewcommand*{\cftsecnumwidth}{3em} 
\renewcommand*{\cftsubsecnumwidth}{3em} 

% -------Document------------- %
%%Début du document
\AtBeginDocument{%
\maketitle
\PageSuivanteStandard
%\leftskip5cm\relax
}

%%Fin du document -> mettre la page standard

\AtEndDocument{%
  \clearpage
  \loadgeometry{DernierePage}
  \fontspec{FiraSans-Regular}\fontsize{12pt}{15pt}\selectfont
 %% c'est mon dernier mot
}

% ---------------------------- %
