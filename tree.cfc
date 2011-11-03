<!--- 
*
*  APPLICATION: CFRemoteTree
*  FILENAME: tree.cfc
*	AUTHOR: Chris Chain (sirveloz [at] gmail [dot] com)
*  DESCRIPTION: Processor component for CFRemoteTree
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
--->
<cfcomponent displayname="tree query processor">

    <cffunction name="appendTreeChild" access="remote" output="yes" returntype="string" returnformat="plain" hint="adds a tree child to the bottom of the subtree">
        <cfargument name="id" type="numeric" required="yes" hint="the ID of the parent node">
        <cfargument name="text" type="string" required="yes" hint="the text name of the new node">
        <cfquery name="qAppend" datasource="remotetree">
            DECLARE @lastChild INT;
            SET @lastChild=(SELECT rt FROM tree WHERE id=#id#);
            UPDATE tree SET lft=lft+2 WHERE lft>=@lastChild;
            UPDATE tree SET rt=rt+2 WHERE rt>=@lastChild;
            SET NOCOUNT ON INSERT INTO tree (text,lft,rt) VALUES ('#FORM.text#',@lastChild,@lastChild+1) SELECT id=@@identity SET NOCOUNT OFF
        </cfquery>
        <cfcontent type="text/plain" reset="Yes">
        {"success":true,"id":#qAppend.id#}
    </cffunction>
    
    <cffunction name="insertTreeChild" access="remote" output="yes" returntype="string" returnformat="plain" hint="adds a tree child to the top of the subtree">
        <cfargument name="id" type="numeric" required="yes" hint="the ID of the parent node">
        <cfargument name="text" type="string" required="yes" hint="the text name of the new node">
        <cfquery name="qInsert" datasource="remotetree">
            DECLARE @pLft INT;
            SET @pLft=(SELECT lft FROM tree WHERE id=#id#);
            UPDATE tree SET lft=lft+2 WHERE lft>@pLft;
            UPDATE tree SET rt=rt+2 WHERE rt>@pLft;  
            SET NOCOUNT ON INSERT INTO tree (text,lft,rt) VALUES ('#FORM.text#',@pLft+1,@pLft+2) SELECT id=@@identity SET NOCOUNT OFF
        </cfquery>
        <cfcontent type="text/plain" reset="Yes">
        {"success":true,"id":#qInsert.id#}
    </cffunction>
    
    <cffunction name="getTree" access="remote" output="yes" returntype="string" returnformat="plain" hint="retrieves the tree structure and outputs it in JSON format">
      <!--- get the tree --->
      <cfquery name="qTree" datasource="remotetree">
            SELECT node.id,node.text,node.lft,node.rt,
                (SELECT COUNT(*) FROM tree AS parent WHERE parent.lft < node.lft AND parent.rt > node.rt) depth,
            (node.rt-node.lft-1)/2 childNodes FROM tree AS node ORDER BY node.lft ASC
      </cfquery>
      <!--- assemble the output --->
      <cfloop query="qTree">
        <cfscript>
            if(recordCount GT currentRow){
                //first row, open the JSON array
                if(currentRow EQ 1){
                    writeOutput('[');
                }
                //get the depth value for the next row
                nextDepth=depth[currentRow+1];
            }else{
                nextDepth=0;
            }
            //output node data
            writeOutput('{"id":#id#,"text":"#text#","leaf":');
            //output leaf boolean and open child array if necessary
            if(childNodes){
                writeOutput('false,"children":[');
            }else{
                writeOutput('true}');
                //close child array if this is the last child
                if(nextDepth LT depth){
                  writeOutput(repeatString(']}',depth-nextDepth));
                }
                //append comma if still outputting members
                if(nextDepth){
                    writeOutput(',');
                }else{
                    writeOutput(']');
                }
            }
      </cfscript>
      </cfloop>
    </cffunction>
    
    <cffunction name="moveTreeNode" access="remote" output="yes" returntype="string" returnformat="plain" hint="moves a node within the tree">
        <cfargument name="id" type="numeric" hint="the ID of the item that is moving">
        <cfargument name="target" type="numeric" hint="the ID of the location the item is moving to">
        <cfargument name="point" type="string" hint="the desired relationship of the node that is moving to the target">
        <!--- get rows for node and target --->
        <cfquery name="qNode" datasource="remotetree">
            SELECT lft,rt,rt-lft+1 width FROM tree WHERE id=#id#
        </cfquery>
        <cfquery name="qTarget" datasource="remotetree">
            SELECT lft,rt FROM tree WHERE id=#target#
        </cfquery>
        <cfscript>
            //set destination var based on action being performed
            switch(point){
                case "above":
                    dest=qTarget.lft;
                    break;
                case "below":
                    dest=qTarget.rt+1;
                    break;
                case "append":
                    dest=qTarget.rt;
                    break;
            }
        </cfscript>
        <!--- make room for new node/subtree --->
        <cfquery datasource="remotetree">
            UPDATE tree SET lft=lft+#qNode.width# WHERE lft>=#dest#;
            UPDATE tree SET rt=rt+#qNode.width# WHERE rt>=#dest#
        </cfquery>
        <cfscript>
            //modify L/R values if node was shifted
            if(qNode.lft GTE dest){
                qNode.lft=qNode.lft+qNode.width;
                qNode.rt=qNode.rt+qNode.width;
            }
        </cfscript>
        <!--- perform the move and finalize the L/R values --->
        <cfquery datasource="remotetree">
            UPDATE tree SET lft=lft+#dest-qNode.lft# WHERE lft>=#qNode.lft# AND lft<=#qNode.rt#;
            UPDATE tree SET rt=rt+#dest-qNode.lft# WHERE rt>=#qNode.lft# AND rt<=#qNode.rt#;
            UPDATE tree SET lft=lft+(-#qNode.width#) WHERE lft>=#qNode.rt+1#;
            UPDATE tree SET rt=rt+(-#qNode.width#) WHERE rt>=#qNode.rt+1#
        </cfquery>
        <cfcontent type="text/plain" reset="Yes">
        {"success":true}
    </cffunction>
    
    <cffunction name="printTree" access="remote" output="yes" returntype="string" returnformat="plain" hint="prints the tree structure">
      <!--- get the tree --->
      <cfquery name="qTree" datasource="remotetree">
            SELECT node.id,node.text,node.lft,node.rt,
                (SELECT COUNT(*) FROM tree AS parent WHERE parent.lft < node.lft AND parent.rt > node.rt) depth,
            (node.rt-node.lft-1)/2 childNodes FROM tree AS node ORDER BY node.lft ASC
      </cfquery>
      <!--- assemble the output --->
      <cfloop query="qTree">
        <cfscript>
            if(recordCount GT currentRow){
                //first row, open the JSON array
                if(currentRow EQ 1){
                    writeOutput('<ul>');
                }
                //get the depth value for the next row
                nextDepth=depth[currentRow+1];
            }else{
                nextDepth=0;
            }
            //output node data
            writeOutput('<li>#text# <span style="font:9px Verdana, Geneva, sans-serif; color: ##666;">(id:#id# | lft:#lft# | rt:#rt# | depth:#depth# | childNodes:#childNodes#)</span>');
            //output leaf boolean and open child array if necessary
            if(childNodes){
                writeOutput('<ul>');
            }else{
                writeOutput('</li>');
                //close child array if this is the last child
                if(nextDepth LT depth){
                  writeOutput(repeatString('</ul></li>',depth-nextDepth));
                }
                //append comma if still outputting members
                if(NOT nextDepth){
                    writeOutput('</ul>');
                }
            }
      </cfscript>
      </cfloop>
    </cffunction>
    
    <cffunction name="removeTreeNode" access="remote" output="yes" returntype="string" returnformat="plain" hint="deletes a node from the tree">
        <cfargument name="id" type="numeric" required="yes" hint="the ID of the parent node">
        <cfquery datasource="remotetree">
            DECLARE @nodeL INT,@nodeR INT,@width INT;
            SELECT @nodeL=lft,@nodeR=rt,@width=rt-lft+1 FROM tree WHERE id=#id#;
            DELETE FROM tree WHERE lft BETWEEN @nodeL AND @nodeR;
            UPDATE tree SET lft = lft - @width WHERE lft > @nodeR;
            UPDATE tree SET rt = rt - @width WHERE rt > @nodeR
        </cfquery>
        <cfcontent type="text/plain" reset="Yes">
        {"success":true}
    </cffunction>
    
    <cffunction name="renameTreeNode" access="remote" output="yes" returntype="string" returnformat="plain" hint="renames a node">
        <cfargument name="id" type="numeric" required="yes" hint="the ID of the node to rename">
        <cfargument name="newText" type="string" required="yes" hint="the new text name of the node">
        <cfquery datasource="remotetree">
            UPDATE tree SET text='#newText#' WHERE id=#id#  
        </cfquery>
        <cfcontent type="text/plain" reset="Yes">
        {"success":true}
    </cffunction>
    
    <cffunction name="setupDB" access="remote" output="yes" returntype="string" hint="creates (or recreates) the tree table in the remotetree database">
    	<cfquery datasource="remotetree">
            IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tree]') AND type in (N'U'))
            DROP TABLE [dbo].[tree];
            CREATE TABLE [dbo].[tree](
                [id] [int] IDENTITY(1,1) NOT NULL,
                [text] [varchar](50) NULL,
                [lft] [int] NULL,
                [rt] [int] NULL,
             CONSTRAINT [PK_tree] PRIMARY KEY CLUSTERED 
            (
                [id] ASC
            )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
            ) ON [PRIMARY];
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Food', 1, 18);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Fruit', 2, 11);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Red', 3, 6);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Cherry', 4, 5);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Yellow', 7, 10);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Banana', 8, 9);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Meat', 12, 17);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Beef', 13, 14);
            INSERT [dbo].[tree] ([text], [lft], [rt]) VALUES (N'Pork', 15, 16);
    	</cfquery>
        Tree table successfully created!
    </cffunction>
    
    <cffunction name="convertTree" access="remote" output="yes" hint="converts an adjacency model table to a MPTT (nested set) tree - note: you must add the lft and rt columns to the table first!">
      <cfargument name="parent" type="numeric" required="yes">
      <cfargument name="lft" type="numeric" required="yes">
      <cfset rt=lft+1>
      <cfquery name="tree" datasource="remotetree">
        SELECT id,text FROM tree WHERE parent=#parent#
      </cfquery>
      <cfloop query="tree">
        <cfset rt=convertTree(id,rt)>
      </cfloop>
      <cfquery datasource="remotetree">
        UPDATE tree SET lft=#lft#,rt=#rt# WHERE id=#parent#
      </cfquery>
      <cfreturn rt+1>
    </cffunction>

</cfcomponent>
