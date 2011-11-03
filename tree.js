/*
*
*  APPLICATION: CFRemoteTree
*  FILENAME: tree.js
*	LastChangedBy: Chris Chain (sirveloz [at] gmail [dot] com)
*	$LastChangedDate: 2010-11-10 22:25:22 -0800 (Wed, 10 Nov 2010) $
*	$Revision: 13 $
*  DESCRIPTION: ExtJS for CFRemoteTree
*  COPYRIGHT: 2010 Chris Chain
*  LICENSE: This file is part of cfremotetree.
*
*  cfremotetree is free software: you can redistribute it and/or modify
*  it under the terms of the Lesser GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  (at your option) any later version.
*
*  cfremotetree is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  Lesser GNU General Public License for more details.
*
*  You should have received a copy of the lesser GNU General Public License
*  along with cfremotetree.  If not, see <http://www.gnu.org/licenses/>.
*
*/
Ext.ns('demo');
Ext.state.Manager.setProvider(new Ext.state.CookieProvider());
// demo tree configuration
demo.tree = new Ext.ux.tree.RemoteTreePanel({
	id:'remoteTree',
	autoScroll:true,
	rootVisible:false,
	paramNames:{ //map cmd to method for CFC (must define all params)
		cmd:'method',
		id:'id',
		target:'target',
		point:'point',
		text:'text',
		newText:'newText',
		oldText:'oldText'
	},
	root:{
		nodeType:'async',
		id:'0',
		text:'Tree Demo',
		expanded:true,
		uiProvider:false
	},
	loader:{
		url:'tree.cfc',
		preloadChildren:true,
		baseParams:{
			method:'getTree'
		}
	}
});
Ext.onReady(function(){
	Ext.QuickTips.init();
	demo.win = new Ext.Window({
		title:'RemoteTreePanel Demo',
		autoScroll:true,
		closable:false,
		border:false,
		height:480,
		layout:'fit',
		maximizable:true,
		width:640,
		items:demo.tree,
		tools:[{
			id:'print',
			qtip:'Print Tree',
			handler:function(){
				window.open('tree.cfc?method=printTree');
			}
		}]
	});
	demo.win.show();
});