// Copyright (с) 2013 Gushcha Anton <ncrashed@gmail.com>
/*
 * This file is part of Foguan Engine.
 * 
 * Foguan Engine is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Foguan Engine is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Foguan Engine.  If not, see <http://www.gnu.org/licenses/>.
 */
package drossy.stars.api.gui.mainmenu;

import drossy.stars.api.gui.IButton;
import drossy.stars.api.gui.IGuiScreen;

/**
 * Application main menu. It handles set of buttons to access another screens.
 * 
 * @author ncrashed
 */
public interface IMainMenu extends IGuiScreen
{
    /**
     * Add button to main menu.
     * @param button 
     */
    void addButton(IButton button);
    
    /**
     * Retrusn button by name;
     * @param name
     * @return Button if name exists and null if not finded.
     */
    IButton getButton(String name);
}
