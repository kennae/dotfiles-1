module Machine where

import Control.Monad
import Control.Monad.List
import Data.Monoid
import Data.List (isPrefixOf)
import Data.Maybe
import Control.Applicative ((<$>))
import System.Environment (getEnvironment)
import System.Directory (getDirectoryContents)
import System.FilePath
import System.Posix.Unistd (getSystemID, nodeName)

import XMonad hiding (workspaces)
import XMonad.Actions.TopicSpace
import XMonad.Hooks.ManageHelpers

import SortWindows
import Utils
import Workspaces

data Machine = Machine
    { rootDir     :: String
    , workspaces  :: [(WorkspaceId, WS)]
    , tweaks      :: Tweaks
    , defaultTerm :: String
    }

instance Profile Machine where
    getTweaks         = tweaks
    getWSNames        = map fst . workspaces
    getWorkspace p ws = lookup ws (workspaces p)
    getLayoutIcon p   = (rootDir p </>) . ("icons/" </>) . ("layout-" ++) . (<.> ".xbm")
    getTerminal       = defaultTerm

getMachine :: IO Machine
getMachine = do
    host <- nodeName <$> getSystemID
    root <- (</> ".xmonad/") <$> getHome
    return $ case host of
        _ -> gmzlj root

data W = W String [Query Bool] (Maybe Dir) (Maybe (X ()))

defaultMachine :: String -> Tweaks -> [W] -> Machine
defaultMachine root tweaks w = Machine
    { rootDir       = root
    , workspaces    = [ mkWS i ws | (ws, i) <- zip w [1..] ]
    , tweaks        = tweaks
    , defaultTerm   = "urxvtc"
    }
  where
    mkWS i (W name r d x) = (name, WS
        { wsIndex  = i
        , wsIcon   = Just $ root </> "icons/" </> name <.> ".xbm"
        , wsRules  = r
        , wsDir    = d
        , wsAction = x
        })

gmzlj :: Dir -> Machine
gmzlj root = defaultMachine root defaultTweaks
    [ W "work"   [ className `queryAny` [ "Firefox", "Chromium", "Zathura", "Thunar", "Gimp" ]
                   , title     =? "MusicBrainz Picard"
                   , className ~? "^[Ll]ibre[Oo]ffice" ]
                   Nothing
                   (Just $ spawn "firefox")
    , W "term"   [] Nothing Nothing
    , W "code"   [] (Just "~/projects") Nothing
    , W "chat"   [ className `queryAny` [ "Empathy", "Pidgin", "Skype" ] ]
                   Nothing
                   (Just $ spawn "pidgin" >> spawn "skype")
    , W "virt"   [ className =? "VirtualBox" ]
                   Nothing
                   (Just $ spawn "VirtualBox --startvm 'Windows 7'")
    , W "games"  [ className `queryAny` [ "Sol", "Pychess", "net-minecraft-LauncherFrame", "zsnes", "Wine", "Dwarf_Fortress" ] ]
                   Nothing
                   (Just $ spawn "sol")
    ]