/*****************************************************************************************************/
/*                           Webinterface for PolarBarMailer                                         */
/*                     by Peter Lueersen <Peter@warp-ecs-owl.de>                                     */
/*                                        V 0.14                                                     */
/*****************************************************************************************************/
/* This program is free software                                                                     */
/* you can redistribute it and/or modify it under the terms of the GNU General Public License        */
/* as published by the Free Software Foundation; either version 2 of the License,                    */
/* or (at your option) any later version.                                                            */
/*                                                                                                   */
/* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY          */
/* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.         */
/* See the GNU General Public License for more details.                                              */
/*                                                                                                   */
/* You should have received a copy of the GNU General Public License along with this program         */
/* if not, write to the                                                                              */
/* Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.           */
/*****************************************************************************************************/
/* SYSTEM SOFTWARE:                                                                                  */
/*      eComstation V1.14             www.ecomstation.com                                            */
/*      PolarBarMailer V1.25a         www.polarbar.org, polarbar.netfang.net, www.polarbar.net       */
/*      Apache V1.3.27                www.apache.org                                                 */
/* BROWSER:                                                                                          */
/*      Netscape Communicator                                                                        */
/*      Mozilla 1.6b                  www.mozilla.org                                                */
/*      IBM Browser 2.0               www.ibm.com                                                    */
/*****************************************************************************************************/

/*           Feste Globale Variablen                */
Globals.!ext='EXE'                                                                      /*Filetype EXE or CMD                  */
Globals.!ver='0.14'                                                                     /*Versinon                             */

signal on syntax name fehler                                                            /*Wenn ein Programmfehler auftritt      */

_starttimer:                                                                            /*Start of main routine                 */
   CALL Time 'E'

/*================*/
/* INSTALLATION   */
/*================*/
IF RxFuncQuery('SysLoadFuncs') <> 0 THEN DO
   CALL RxFuncAdd 'SysLoadFuncs','RexxUtil','SysLoadFuncs'
   CALL RxFuncAdd 'SysFileDelete','RexxUtil','SysFileDelete'
   loaded = 1
END
CALL SysLoadFuncs

CALL RxFuncAdd "XtraLoadFuncs","XtraRexx","XtraLoadFuncs"
CALL XtraLoadFuncs "quiet"

If XtraVersion()<"0.44" Then Do
   say "XtraRexx v0.44+ required."
   exit
End
call XtraSetDefaultDelay 5

/*      Globale Variablen aus der POLARBARWEB.CFG   */
Globals.!PBMPath=''                                                                     /*Path to PolarBarMailer               */
Globals.!MailDataPath=''                                                                /*Path to MailData from PolarBarMailer */
Globals.!HtmlTableColor='WHITE'                                                         /*Table Color                          */
Globals.!Emailmax='25'                                                                  /*Max Mails                            */
Globals.!html_body_line='<BODY onload="lade()" bgcolor="#EFEFEF" text="#000000">'       /*The BODY-Tag Line in the html outputs*/
Globals.!Show_HTML='NO'                                                                 /*Text and HTML                        */
Globals.!Lang='EN'                                                                      /*Language Support                     */
Globals.!Log='NO'                                                                       /*Log of Work                          */
Globals.!CGI_BIN='/cgi-bin/'                                                            /*Path to CGI-BIN of the Web-Server    */
Globals.!FreeAccess='0.0.0.0'                                                           /*Free access for IP                   */
Globals.!pbmw_user='USER'                                                               /*User for free access                 */
Globals.!pbmw_password='PASSWORD'                                                       /*Password for access                  */
parse SOURCE Globals.!myos .

/*      Globale Variablen aus CGI Environment   */
Globals.!SERVER_SOFTWARE=getEnv('SERVER_SOFTWARE')                                      /*CGI Environment                      */
Globals.!SERVER_NAME=getEnv('SERVER_NAME')                                              /*CGI Environment                      */
Globals.!GATEWAY_INTERFACE=getEnv('GATEWAY_INTERFACE')                                  /*CGI Environment                      */
Globals.!SERVER_PROTOCOL=getEnv('SERVER_PROTOCOL')                                      /*CGI Environment                      */
Globals.!SERVER_PORT=getEnv('SERVER_PORT')                                              /*CGI Environment                      */
Globals.!REQUEST_METHOD=getEnv('REQUEST_METHOD')                                        /*CGI Environment                      */
Globals.!PATH_INFO=getEnv('PATH_INFO')                                                  /*CGI Environment                      */
Globals.!PATH_TRANSLATED=getEnv('PATH_TRANSLATED')                                      /*CGI Environment                      */
Globals.!SCRIPT_NAME=getEnv('SCRIPT_NAME')                                              /*CGI Environment                      */
Globals.!QUERY_STRING=getEnv('QUERY_STRING')                                            /*CGI Environment                      */
Globals.!REMOTE_HOST=getEnv('REMOTE_HOST')                                              /*CGI Environment                      */
Globals.!REMOTE_ADDR=getEnv('REMOTE_ADDR')                                              /*CGI Environment                      */
Globals.!AUTH_TYPE=getEnv('AUTH_TYPE')                                                  /*CGI Environment                      */
Globals.!REMOTE_USER=getEnv('REMOTE_USER')                                              /*CGI Environment                      */
Globals.!REMOTE_IDENT=getEnv('REMOTE_IDENT')                                            /*CGI Environment                      */
Globals.!CONTENT_TYPE=getEnv('CONTENT_TYPE')                                            /*CGI Environment                      */
Globals.!CONTENT_LENGTH=getEnv('CONTENT_LENGTH')                                        /*CGI Environment                      */
Globals.!HTTP_ACCEPT=getEnv('HTTP_ACCEPT')                                              /*CGI Environment                      */
Globals.!HTTP_USER_AGENT=getEnv('HTTP_USER_AGENT')                                      /*CGI Environment                      */

/*           Feste Globale Variablen 2           */
Globals.!File='POLARBARWEB.'||Globals.!ext                                              /*Name of File                         */
Globals.!CONFIGFile='PBWCONFIG.'||Globals.!ext                                          /*Name of CONFIG - File                */
Globals.!LOGFile='POLARBARWEB.LOG'                                                      /*Name of DEBUG - File                 */
Globals.!myinfo='PolarbarWeb/2  &copy; 2005,2006 by Peter L&uuml;ersen'                 /*Info Topline                         */
Globals.!BOUNDARY=""

/*Hilfsvariablen fuer (STR1UPPER=TRANSLATE(STR1,tabout,taborg))*/
taborg=XRANGE('a','z')
tabout=XRANGE('A','Z')

undnocheine=0
ersterdurchlauf=1

/*Lesen der Config (/cgi-bin/POLARBARWEB.CFG)*/
Dateiname='POLARBARWEB.CFG'
erg=XtraFileOpen(Dateiname, "r+s", 2000)
        call XtraFileGetLines Dateiname, Dateilines.
erg=XtraFileClose(Dateiname)
/*Auswerten der Datei*/
DO i=1 TO Dateilines.0
        Zeile=Dateilines.i
        if Zeile \= '' then do
                if pos('#',Zeile,1) \= 1 then do
                        pos1=pos('=', Zeile)
                        Option=SUBSTR(Zeile, 1,pos1-1)
                        Option_Value=SUBSTR(Zeile,pos1+1,length(Zeile)-pos1)
                        /* SAY Option || '==' || Option_Value || '<BR>'*/
                        if OPTION='PBM_Path' then
                                Globals.!PBMPath=Option_Value
                        if OPTION='Mail_Data_Path' then
                                Globals.!MailDataPath=Option_Value
                        if OPTION='html_table_color' then
                                Globals.!HtmlTableColor=Option_Value
                        if OPTION='html_body_line' then
                                Globals.!html_body_line=Option_Value
                        if OPTION='Email_Max' then
                                Globals.!Emailmax=Option_Value
                        if OPTION='Show_HTML' then
                                Globals.!Show_HTML=TRANSLATE(Option_Value,tabout,taborg)
                        if OPTION='Lang' then do
                                 Globals.!Lang='GE'
                                 Lang=TRANSLATE(Option_Value,tabout,taborg)
                                 if Lang='EN' then
                                    Globals.!Lang='EN'
                                 if Lang='GE' then
                                    Globals.!Lang='GE'
                        end
                        if OPTION='CGI-BIN_Path' then
                                Globals.!CGI_BIN=Option_Value
                        if OPTION='Debug' then
                                Globals.!Log=TRANSLATE(Option_Value,tabout,taborg)
                        if OPTION='free_access_for_ip' then
                                Globals.!FreeAccess=Option_Value
                        if OPTION='pbmw_user' then
                                Globals.!pbmw_user=Option_Value
                        if OPTION='pbmw_password' then
                                Globals.!pbmw_password=Option_Value
                end
        end
END

Uebergabe_ARG1=ARG(1)
/* FÅr Apache 2.x   */
STR1=Uebergabe_ARG1
STR1UPPER=TRANSLATE(STR1,tabout,taborg)
/* \? ersetzen, */
if LASTPOS("\",STR1UPPER) > 0 then do
   STR2='\'
   STR3=''
   CALL STR123
END
Uebergabe_ARG1=STR1
/* FÅr Apache 2.x   */


if Globals.!Log='YES' then do
        IF Uebergabe_ARG1='' THEN
                erg=SysFileDelete(Globals.!LOGFile)
        CALL LINEOUT Globals.!LOGFile,'**********************************************************************'
        CALL LINEOUT Globals.!LOGFile,'Version            : ' || Globals.!ver
        CALL LINEOUT Globals.!LOGFile,' '
        CALL LINEOUT Globals.!LOGFile,'ARG                : ' || Uebergabe_ARG1
        CALL LINEOUT Globals.!LOGFile,'----------------------------------------------------------------------'
        CALL LINEOUT Globals.!LOGFile,'PBM_Path           : ' || Globals.!PBMPath
        CALL LINEOUT Globals.!LOGFile,'Mail_Data_Path     : ' || Globals.!MailDataPath
        CALL LINEOUT Globals.!LOGFile,'html_table_color   : ' || Globals.!HtmlTableColor
        CALL LINEOUT Globals.!LOGFile,'html_body_line     : ' || Globals.!html_body_line
        CALL LINEOUT Globals.!LOGFile,'Email_Max          : ' || Globals.!Emailmax
        CALL LINEOUT Globals.!LOGFile,'Show_HTML          : ' || Globals.!Show_HTML
        CALL LINEOUT Globals.!LOGFile,'CGI_BIN            : ' || Globals.!CGI_BIN
        CALL LINEOUT Globals.!LOGFile,'Lang               : ' || Globals.!Lang
        CALL LINEOUT Globals.!LOGFile,'Debug              : ' || Globals.!Log
        CALL LINEOUT Globals.!LOGFile,'======================================================================'
end

Globals.!PBMMaildataPath=Globals.!MailDataPath

/***********************************************/
/* Datum umwandeln                             */
/***********************************************/
dates=DATE('S')
datel=DATE('L')
dateu=DATE('U')
dateo=DATE('O')
years=SUBSTR(dates,1,4)
months=SUBSTR(dates,5,2)


/**********************************************************************/
/* Begin of main routine                                              */
/**********************************************************************/
call Begin_HTML
IF Uebergabe_ARG1='' THEN do
        /**************************************************************/
        /* Login auswerten                                            */
        /**************************************************************/
        Uebergabe_ARG1='LEER'
        if pos(Globals.!FreeAccess,Globals.!REMOTE_ADDR )=1 then
                Uebergabe_ARG1='READACCOUNT?'
        if Globals.!FreeAccess='.' then
                Uebergabe_ARG1='READACCOUNT?'
        if Globals.!FreeAccess='0.0.0.0' then
                Uebergabe_ARG1='LEER'
        if Uebergabe_ARG1='LEER' then do
                say '<form method="post" autocomplete="off" action="'|| Globals.!CGI_BIN || Globals.!CONFIGFile ||'" name="PolarbarWeb login">'
                say '<input type="hidden" name="flogin" value="1">'
                say '<center>'
                say ' <table border="0" cellspacing="10">'
                say ' <tr>'
                say '  <br>'
                say '  <font face="verdana,arial" SIZE=+2><b>PolarbarWeb/2 login<br></b></font>'
                say '  <br>'
                say '  <br>'
                if Globals.!Lang='GE' then do
                        say '  Anmeldung n&ouml;tig !<br>'
                        say '  Bitte geben Sie Name und Passwort ein.<br>'
                end
                if Globals.!Lang='EN' then do
                        say '  Authorization required !<br>'
                        say '  Please insert your name and password.<br>'
                end
                say '  <td align="right"> Name:</td>'
                say '  <td align="left"><input type="text" name="l" size="25"></td>'
                say ' </tr>'
                say ' <tr>'
                if Globals.!Lang='GE' then
                        say '  <td align="right">Passwort:</td>'
                if Globals.!Lang='EN' then
                        say '  <td align="right">Password:</td>'
                say '  <td align="left"><input type="password" name="p" size="25"></td>'
                say ' </tr>'
                say ' </table>'
                say ' <p><input type="submit" value="Login"></p>'
                say ' '
                say '</center>'
                say '</form>'
                say '<p>&nbsp;</p>'
                say '<center>'
                say 'Powered by '||Globals.!myos
                say '</center>'
                say '<hr size=1 noshade>'
                say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
                if Globals.!Lang='GE' then
                     say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
                if Globals.!Lang='EN' then
                     say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
                say '</body>'
                say '</html>'
                EXIT
        end
end

SIGNAL UEBERGABE
erg=STREAM(Globals.!LOGFile, 'C', "CLOSE")

IF loaded = 1 THEN CALL SysDropFuncs
EXIT
/**********************************************************************/
/* End of main routine                                                */
/**********************************************************************/


/**********************************************************************/
/* Kopf fuer alle Seiten                                              */
/**********************************************************************/
Begin_HTML:
        say 'Content-Type: text/html;  charset=ISO-8859-1'
        say ''
        say '<!doctype html public "-//w3c//dtd html 4.0 transitional//en">'
        say '<!-- File automatically generated by PolarbarWeb/2 Ver.:' || Globals.!ver || ' on ' || DATE() || ' at ' || TIME('N') || ' -->'
        say '<!-- (C) COPYRIGHT Peter Lueersen 2003,2004,2005,2006       -->'
        say '<!-- All Rights Reserved                                    -->'
        say '<!-- Licensed Materials - Property of Peter Lueersen        -->'
        say '<html>'
        say '<head>'
        say '<meta http-equiv="expires" content="0">'
        say '<meta name="author" content="Peter Lueersen">'
        say '<meta http-equiv="content-type">'
        say '<meta NAME="Robots" CONTENT="NOINDEX, NOFOLLOW">'
        say ''
        say '<title>' || Globals.!myinfo || '</title>'
        say ''
        say '<style type="text/css">'
        say '   a:link { font-family : verdana, arial;font-weight:normal; color:#0000E0; text-decoration:none }'
        say '   a:visited { font-family : verdana, arial;font-weight:normal; color:#0000E0; text-decoration:none }'
        say '   a:hover { font-family : verdana, arial;font-weight:normal; color:#E00000; text-decoration:none }'
        say '   a:active { font-family : verdana, arial;font-weight:normal; color:#E00000; text-decoration:none }'
        say '   a:focus { font-family : verdana, arial;font-weight:normal; color:#00E000; text-decoration:none }'
        say '</style>'
        say ''
        say '<script language="JavaScript">'
        say '<!--'
        say '    function scrollit_r2l(seed)'
        say '    {'
        say '     var msg = "PolarbarWeb/2 - Running all over the world";'
        say '     var out = " ";'
        say '     var c = 1;'
        say '     if (seed > 100)'
        say '     {'
        say '     seed--;'
        say '     var cmd="scrollit_r2l(" + seed + ")";'
        say '     timerTwo=window.setTimeout(cmd,100);'
        say '     }'
        say '     else if (seed <= 100 && seed > 0)'
        say '     {'
        say '     for (c=0 ; c < seed ; c++)'
        say '     {'
        say '     out+=" ";'
        say '     }'
        say '     out+=msg;'
        say '     seed--;'
        say '     var cmd="scrollit_r2l(" + seed + ")";'
        say '     window.status=out;'
        say '     timerTwo=window.setTimeout(cmd,100);'
        say '     }'
        say '     else if (seed <= 0)'
        say '     {'
        say '     if (-seed < msg.length)'
        say '     {'
        say '     out+=msg.substring(-seed,msg.length);'
        say '     seed--;'
        say '     var cmd="scrollit_r2l(" + seed + ")";'
        say '     window.status=out;'
        say '     timerTwo=window.setTimeout(cmd,100);'
        say '     }'
        say '     else'
        say '     {'
        say '     window.status=" ";'
        say '     timerTwo = window.setTimeout("scrollit_r2l(100)",75);'
        say '     }'
        say '     }'
        say '    }'
        say ''
        say '    function lade()'
        say '    {'
        say '    timerONE=window.setTimeout("scrollit_r2l(100)",500);'
        say '    }'
        say '//-->'
        say '</script>'
        say ''
        say '</head>'
        say ''
        say Globals.!html_body_line
        say '<table align=center width=100% border="0" cellspacing="0" cellpadding="0">'
        say '   <tr>'
        say '   <td align=center> <Font face="verdana,arial"><B>' || Globals.!myinfo || '</B> Ver.: ' || Globals.!ver || '</font><BR></td>'
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
return


/**********************************************************************/
/* öbergaben auswerten                                                */
/**********************************************************************/
UEBERGABE:;
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> öBERGABE:  ' || Uebergabe_ARG1
        /* öbergabe Komando erstellen */
        UebergabeARG = translate(Uebergabe_ARG1," ","?")
        if pos('"',UebergabeARG,1) = 1 then
                UebergabeARG=SUBSTR(UebergabeARG, 2,LENGTH(UebergabeARG) - 2)
        pos1=pos(' ', UebergabeARG)
        Komando=SUBSTR(UebergabeARG, 1,pos1-1)
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Komando:  ' || Komando

/* ================================================================== */
/* Configuration bearbeiten                                           */
/* ================================================================== */
IF Komando = 'CONFIG' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start CONFIG'
        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Verlassen der Konfiguration</A></td>'
        if Globals.!Lang='EN' then
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Exit  Configuration</A></td>'
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<br>'
        if Globals.!Lang='GE' then DO
                say '<p>'
                say '   <center><font size=2>Achtung! Keine Umlaute in Datei- oder Verzeichnissnamen verwenden !</font></center>'
                say '<p>'
                say '<table align=center cellpadding=3 cellspacing=0 border=1>'
                say '<tr><td>Option</td><td>Wert</td></tr>'
        END
        if Globals.!Lang='EN' then DO
                say '<p>'
                say '   <center><font size=2>Attention! Dont use german umlaut in file or directory names at time !</font></center>'
                say '<p>'
                say '<table align=center cellpadding=3 cellspacing=0 border=1>'
                say '<tr><td>Option</td><td>Value</td></tr>'
        END

        /*Path to PolarBarMailer               */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Path to PolarBarMailer</td>'
        say '   <td><input type=text name="PBMPath" value='||Globals.!PBMPath||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        /*Path to MailData from PolarBarMailer */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Path to MailData</td>'
        say '   <td><input type=text name="MailDataPath" value='||Globals.!MailDataPath||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        /*Table Color                          */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Table Color</td>'
        say '   <td><input type=text name="HtmlTableColor" value='||Globals.!HtmlTableColor||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        /*Max Mails                            */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Max Mails</td>'
        say '   <td><input type=text name="Emailmax" value='||Globals.!Emailmax||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        /*Text and HTML                        */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Show HTML YES-NO</td>'
        say '   <td><input type=text name="Show_HTML" value='||Globals.!Show_HTML||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        /*Language Support                     */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Language GE-EN</td>'
        say '   <td><input type=text name="Lang" value='||Globals.!Lang||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        /*Log of Work                          */
        say '<tr bgcolor=white> <form action="' || Globals.!CGI_BIN||Globals.!CONFIGFile||'" method="post" autocomplete="off">'
        say '   <td>&#160;Debug YES-NO</td>'
        say '   <td><input type=text name="Log" value='||Globals.!Log||' size=60></td>'
        say '   <td><input type=submit value="Set"></td>'
        say '</form> </tr>'

        say '</table>'
        say '<hr size=1 noshade>'
        say '<br>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End CONFIG'
END
/* ================================================================== */
/* Product Info bearbeiten                                            */
/* ================================================================== */
IF Komando = 'INFO' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start INFO'
        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Verlassen der Produktinformation</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO1? > Systeminformation</A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Exit  Product Information</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO1? > System Information</A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<br>'
        say '<table align=center width=90% border="1" cellspacing="1" cellpadding="1">'
        say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
        say '   <td align=center>'
        say '   <br>'
        say '   <font face="verdana,arial" SIZE=+2><b>PolarbarWeb/2 <br></b></font>'
        say '   <br>'
        say '   <br>'
        if Globals.!Lang='GE' then
                say '   <font face="verdana,arial" SIZE=-1>Produktinformation <br></font>'
        if Globals.!Lang='EN' then
                say '   <font face="verdana,arial" SIZE=-1>Product Information <br></font>'
        say '   <br>'
        say '   <font face="verdana,arial">' || Globals.!File || '   Version  ' || Globals.!ver || '<br>'
        say '   <br>'
        say '   '||Globals.!myinfo||'.<br>'
        say '   <br>'
        say '   Program URL:<br>'
        say '   <A Href=http://www.warp-ecs-owl.de> www.warp-ecs-owl.de </A> <br>'
        say '   <A Href=http://www.warp-ecs-owl.de/Peter_PBMWEB.html> www.warp-ecs-owl.de/Peter_PBMWEB.html </A> <br>'
        say '   <br>'
        if Globals.!Lang='GE' then do
                say '   PolarbarWeb/2 ist freie Software! <br>'
                say '   Aus diesem Grunde wird f&uuml;r PolarbarWeb/2<b> keine Haftung jedweder Art </b>&uuml;bernommen.<br>'
                say '   <br>'
                say '   Fehlerberichte und Vorschl&auml;ge richten Sie bitte an Peter@warp-ecs-owl.de <br>'
        end
        if Globals.!Lang='EN' then do
                say '   PolarbarWeb/2 is free software! <br>'
                say '   PolarbarWeb/2 comes with absolutely<b> no Warranty</b>.<br>'
                say '   <br>'
                say '   Contact Peter@warp-ecs-owl.de for bug reports and suggestions.<br>'
        end
        say '   <br>'
        say '   </font></td>'
        say '   </tr>'
        say '</table>'
        say '   <font face="verdana,arial"'
        say '<br>'
        say '   </font>'
        say '<hr size=1 noshade>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End INFO'
END

/* ================================================================== */
/* System Info bearbeiten                                             */
/* ================================================================== */
IF Komando = 'INFO1' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start SYSTEM INFO'
        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Verlassen der Systeninformation</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO?' || '> Produktinformation </A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Exit  System Information</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO?' || '> Product Information </A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<br>'
        say '<table align=center width=90% border="1" cellspacing="1" cellpadding="1">'
        say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
        say '   <td align=center>'
        say '   <br>'
        if Globals.!Lang='GE' then
                say '   <face="verdana,arial" SIZE=+2><b>Systeminformation <br></b></font>'
        if Globals.!Lang='EN' then
                say '   <face="verdana,arial" SIZE=+2><b>System Information <br></b></font>'
        say '   <br>'
        say '   <font face="verdana,arial">' || Globals.!File || '   Version  ' || Globals.!ver || '<br>'
        say '   <br>'
        say '   '||Globals.!myinfo||'.<br>'
        say '   <br>'
        if Globals.!SERVER_SOFTWARE \= '' then
                SAY '  SERVER SOFTWARE <== ' || Globals.!SERVER_SOFTWARE || '<BR>'
        if Globals.!SERVER_NAME \= '' then
                SAY '      SERVER NAME <== ' || Globals.!SERVER_NAME || '<BR>'
        if Globals.!GATEWAY_INTERFACE \= '' then
                SAY 'GATEWAY INTERFACE <== ' || Globals.!GATEWAY_INTERFACE || '<BR>'
        if Globals.!SERVER_PROTOCOL \= '' then
                SAY '  SERVER PROTOCOL <== ' || Globals.!SERVER_PROTOCOL || '<BR>'
        if Globals.!SERVER_PORT \= '' then
                SAY '      SERVER PORT <== ' || Globals.!SERVER_PORT || '<BR>'
        if Globals.!REQUEST_METHOD \= '' then
                SAY '   REQUEST METHOD <== ' || Globals.!REQUEST_METHOD || '<BR>'
        if Globals.!PATH_INFO \= '' then
                SAY '        PATH INFO <== ' || Globals.!PATH_INFO || '<BR>'
        if Globals.!PATH_TRANSLATED \= '' then
                SAY '  PATH TRANSLATED <== ' || Globals.!PATH_TRANSLATED || '<BR>'
        if Globals.!SCRIPT_NAME \= '' then
                SAY '      SCRIPT NAME <== ' || Globals.!SCRIPT_NAME || '<BR>'
        if Globals.!QUERY_STRING \= '' then
                SAY '     QUERY STRING <== ' || Globals.!QUERY_STRING || '<BR>'
        if Globals.!AUTH_TYPE \= '' then
                SAY '        AUTH TYPE <== ' || Globals.!AUTH_TYPE || '<BR>'
        if Globals.!AUTH_TYPE \= '' then
                SAY '      REMOTE HOST <== ' || Globals.!REMOTE_HOST || '<BR>'
        if Globals.!REMOTE_ADDR \= '' then
                SAY '      REMOTE ADDR <== ' || Globals.!REMOTE_ADDR || '<BR>'
        if Globals.!REMOTE_USER \= '' then
                SAY '      REMOTE USER <== ' || Globals.!REMOTE_USER || '<BR>'
        if Globals.!REMOTE_IDENT \= '' then
                SAY '     REMOTE IDENT <== ' || Globals.!REMOTE_IDENT || '<BR>'
        if Globals.!CONTENT_TYPE \= '' then
                SAY '     CONTENT TYPE <== ' || Globals.!CONTENT_TYPE || '<BR>'
        if Globals.!CONTENT_LENGTH \= '' then
                SAY '   CONTENT LENGTH <== ' || Globals.!CONTENT_LENGTH || '<BR>'
        if Globals.!HTTP_ACCEPT \= '' then
                SAY '      HTTP ACCEPT <== ' || Globals.!HTTP_ACCEPT || '<BR>'
        if Globals.!HTTP_USER_AGENT \= '' then
                SAY '  HTTP USER AGENT <== ' || Globals.!HTTP_USER_AGENT || '<BR>'
        say '   <br>'
        say '   </font></td>'
        say '   </tr>'
        say '</table>'
        say '   <font face="verdana,arial"'
        say '<br>'
        say '   </font>'
        say '<hr size=1 noshade>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End SYSTEM INFO'
END

/* ================================================================== */
/* Help bearbeiten                                                    */
/* ================================================================== */
IF Komando = 'HELP' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start HELP'
        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Verlassen der Hilfe </A></td>'
                say '   </tr>'
                say '</table>'
                say '<hr size=1 noshade>'
                say '   <font face="verdana,arial" SIZE=+2><b>Hilfe f&uuml;r PolarbarWeb/2 <br></b></font>'
                say '   <font face="verdana,arial"'
                say '<br>'
                say 'PolarbarWeb/2 ist ein CGI-Webfrontend f&uuml;r den  PolarBarMailer.<br>'
                say 'Mit PolarbarWeb/2 k&ouml;nnen Sie alle E-mails des PolarBarMailer lesen.<br>'
                say '<br>'
                say '<b>Installation:</b> <br>'
                say '<p style="text-indent:0.5cm;">- PBMWEBXXX.ZIP einem Temp - Verzeichniss entpacken.</p>'
                say '<p style="text-indent:0.5cm;">- POLARBARWEB.EXE, PBWCONFIG.EXE and POLARBARWEB.CFG in das cgi-bin Verzeichniss kopieren.</p>'
                say '<p style="text-indent:0.5cm;">- POLARBARWEB.CFG im cgi-bin Verzeichniss editieren.</p>'
                say '<br>'
                say '<b>Programmstart:</b> <br>'
                say '<p style="text-indent:0.5cm;">- PolarbarWeb/2 mit http://&lt;server&gt;/cgi-bin/POLARBARWEB.EXE starten.</p>'
                say '<br>'
                say '<hr size=1 noshade>'
                say '<br>'
                say '<b>BEDIENUNG:</b> <br>'
                say '<br>'
                say '<b>Liste aller Accounts</b><br>'
                say '<p">Hier wird die Liste aller Accounts angezeigt. Der Inhalt des Accounts wird nach Auswahl des gew&uuml;nschten Eintrages angezeigt.</p>'
                say '<br>'
                say '<b>Liste aller Gruppen im Account</b><br>'
                say '<p>Hier wird die Liste aller Gruppen im gew&auml;hlten Account angezeigt. Der Inhalt der Gruppe wird nach Auswahl des gew&uuml;nschten Eintrages angezeigt.</p>'
                say '<p>Ein (@) zeigt an, das sich "Neue E-Mails" in dieser Gruppe befinden. "Neue E-Mails" = E-Mails die Heute empfangen wurden.</p>'
                say '<br>'
                say '<b>Liste der letzten XX Emails im Account</b><br>'
                say '<p>Hier wird die Liste der letzten XX E-Mails in der Gruppe angezeigt. Die E-Mal wird nach Auswahl des gew&uuml;nschten Eintrages angezeigt.</p>'
                say '<p>Die neuste E-Mail befindet sich immer am Anfang der Liste.</p>'
                say '<p>Die Maximale-L&auml;nge der Liste XX=(Anzahl der Eintr&auml;ge), wird durch die Angabe der Listenl&auml;nge in der Konfigurationsdatei POLARBARWEB.CFG im cgi-bin Verzeichniss bestimmt. Siehe hier Email_Max</p>'
                say '<p>Ein (@) zeigt an, das sich um "Neue E-Mails" in dieser Gruppe handelt. "Neue E-Mails" = E-Mails die Heute empfangen wurden.</p>'
                say '<br>'
                say '<hr size=1 noshade>'
                say '<br>'
                say '<b>Die Testumgebung </b><br>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Exit Help </A></td>'
                say '   </tr>'
                say '</table>'
                say '<hr size=1 noshade>'
                say '   <font face="verdana,arial" SIZE=+2><b>Help for PolarbarWeb/2 <br></b></font>'
                say '   <font face="verdana,arial"'
                say '<br>'
                say 'PolarbarWeb/2 is a cgi web frontend for the Email software PolarBarMailer.<br>'
                say 'With PolarbarWeb/2 can you see, read all Emails from PolarBarMailer.<br>'
                say '<br>'
                say '<b>Installation:</b> <br>'
                say '<p style="text-indent:0.5cm;">- Unpack PBMWEBXXX.ZIP to a Temp - Directory.</p>'
                say '<p style="text-indent:0.5cm;">- Copy POLARBARWEB.EXE, PBWCONFIG.EXE and POLARBARWEB.CFG to the cgi-bin Directory.</p>'
                say '<p style="text-indent:0.5cm;">- Edit POLARBARWEB.CFG in the cgi-bin Directory.</p>'
                say '<br>'
                say '<b>Run the Program:</b> <br>'
                say '<p style="text-indent:0.5cm;">- To start PolarbarWeb/2 type http://&lt;server&gt;/cgi-bin/POLARBARWEB.EXE.</p>'
                say '<br>'
                say '<hr size=1 noshade>'
                say '<b>Tested with </b><br>'
        end
        say '<br>'
        say '<b>SYSTEM SOFTWARE:</b> <br>'
        say '<p style="text-indent:0.5cm;">eComstation V1.14             www.ecomstation.com www.ecomstation.de</p>'
        say '<p style="text-indent:0.5cm;">PolarBarMailer V1.25a         www.polarbar.org, polarbar.netfang.net, www.polarbar.net </p>'
        say '<p style="text-indent:0.5cm;">Apache V1.3.27                www.apache.org </p>'
        say '<b>BROWSER:</b> <br>'
        say '<p style="text-indent:0.5cm;">Netscape Communicator </p>'
        say '<p style="text-indent:0.5cm;">Mozilla 1.6b                  www.mozilla.org </p>'
        say '<p style="text-indent:0.5cm;">IBM Browser 2.0               www.ibm.com </p>'
        say '<br>'
        say '<br>'
        say '   </font>'
        say '<hr size=1 noshade>'
        /* Unterschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Verlassen der Hilfe </A></td>'
                say '   </tr>'
                say '</table>'
                say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Exit Help </A></td>'
                say '   </tr>'
                say '</table>'
                say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        end
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End HELP'
END


/**********************************************************************/
/* Lesen aller Accounts und anzeigen                                  */
/**********************************************************************/
IF Komando = 'READACCOUNT' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start READ_ACCOUNT:'
        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO?' || '> Produktinformation </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?CONFIG?' || '> Konfiguration </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?HELP?' || '> Hilfe </A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO?' || '> Product Information </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?CONFIG?' || '> Configuration </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?HELP?' || '> Help </A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        if Globals.!Lang='GE' then
                say ' Liste aller Accounts <BR>'
        if Globals.!Lang='EN' then
                say ' List of all Accounts <BR>'
        say '<hr size=1 noshade>'

        /* Tabelle mit den Accounts erstellen */
        say '<table align=center width=80% border="2" cellspacing="2" cellpadding="2">'
        rc=SysFileTree(Globals.!PBMMaildataPath || '\*.*', 'account', 'D', '*+***')
        if Globals.!Log='YES' then
                CALL LINEOUT Globals.!LOGFile,'->   Account.0            = ' || account.0
        if account.0 > 0 then do
                Call SysStemSort "account.", "D",,,,4
                do i=1 to account.0
                        /*nur den Accountnamen anzeigen*/
                        pos1=lastpos('\', account.i)
                        accountname=SUBSTR(account.i, pos1+1,LENGTH(account.i)-pos1)
                        accountnametranslate=translate(accountname,"|"," ")
                        if Globals.!Log='YES' then do
                                CALL LINEOUT Globals.!LOGFile,'->   Account.' || i ||'            = ' || account.i
                                CALL LINEOUT Globals.!LOGFile,'->   Accountname          = ' || accountname
                                CALL LINEOUT Globals.!LOGFile,'->   Accountnametranslate = ' || accountnametranslate
                        end
                        /*und mit link anzeigen */
                        say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
                        say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountnametranslate || '>' || accountname || '</A></td>'
                        say '   </tr>'
                end
        end
        say '</table>'
        /* Unterschrift erstellen */
        say '<hr size=1 noshade>'
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO?' || '> Produktinformation </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?CONFIG?' || '> Konfiguration </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?HELP?' || '> Hilfe </A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?INFO?' || '> Product Information </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?CONFIG?' || '> Configuration </A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?HELP?' || '> Help </A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        say '</body></html>'
        say ''
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End READ_ACCOUNT:'
end


/* ================================================================== */
/* Liste der Groups im Account bearbeiten                             */
/* ================================================================== */
IF Komando = 'GETACCOUNT' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start GETACCOUNT'
        accountname = SUBSTR(UebergabeARG, pos1+1,LENGTH(UebergabeARG) - pos1)
        accountnametranslate=translate(accountname," ","|")
        if Globals.!Log='YES' then do
                CALL LINEOUT Globals.!LOGFile,'->   Accountname          = ' || accountname
                CALL LINEOUT Globals.!LOGFile,'->   Accountnametranslate = ' || accountnametranslate
        end

        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
        if Globals.!Lang='EN' then
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        if Globals.!Lang='GE' then
                say ' Liste aller Gruppen im Account: ' || accountname || ' <BR>'
        if Globals.!Lang='EN' then
                say ' List of all Groups in Account: ' || accountname || ' <BR>'
        say '<hr size=1 noshade>'

        /* Tabelle mit den Gruppen erstellen */
        say '<table align=center width=80% border="2" cellspacing="2" cellpadding="2">'
        rc=SysFileTree(Globals.!PBMMaildataPath || '\' || accountnametranslate || '\*.*', 'group', 'DT', '*+***')
        /* Die Gruppen werden nach Name sotiert (a->z) angezeigt. */
        if group.0 > 0 then do
                Call SysStemSort "group.", "A","I",,,24,1000
                do i=1 to group.0
                        /* nur den Groupnamen anzeigen */
                        pos1=lastpos('\', group.i)
                        groupname=SUBSTR(group.i, pos1+1,LENGTH(group.i) - pos1)
                        groupnametranslate=translate(groupname,"|"," ")
                        if Globals.!Log='YES' then do
                                CALL LINEOUT Globals.!LOGFile,'->   Group.' || i ||'            = ' || group.i
                                CALL LINEOUT Globals.!LOGFile,'->   Groupname          = ' || groupname
                                CALL LINEOUT Globals.!LOGFile,'->   Groupnametranslate = ' || groupnametranslate
                        end
                        /*PrÅfen ob Mails von heute vorhanden sind*/
                        rc=SysFileTree(Globals.!PBMMaildataPath || '\' || accountnametranslate || '\' || groupname || '\*.INX', 'email', 'FT','*****')
                        /* Die mails werden nach Datum sotiert neuste zuerst. */
                        if email.0 > 0 then do
                                Call SysStemSort "email.", "D","I",,,1,15
                                Dateidatum=SUBSTR(email.1,1,pos('/', email.1,1)+5)
                        end

                        /* Umlaute und Sonderzeichen ersetzen, */
                        zeile=groupname
                        CALL HTML
                        CALL UMLAUTE
                        groupname=zeile
                        /*wenn Mails von heute vorhanden sind, dann (@) */
                        if Dateidatum = dateo & email.0 > 0 then
                                groupname='(@)'||groupname
                        /* und mit link anzeigen */
                        say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
                        say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETGROUP?' || accountname || '?' ||groupnametranslate || '>' || groupname || '</A></td>'
                        say '   </tr>'
                end
        end
        say '</table>'
        /* Unterschrift erstellen */
        say '<hr size=1 noshade>'
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
        if Globals.!Lang='EN' then
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End GETACCOUNT'
END

/* ================================================================== */
/* Liste der Emails (Group im Accont) bearbeiten                      */
/* Es werden neue Mails zuerst angezeigt                              */
/* Wenn in der Liste mehr wie Globals.!Emailmax Eintraege vorhanden   */
/* sind, dann werden nur die letzten Globals.!Emailmax angezeigt.     */
/* Globals.!Emailmax=0 nur EintrÑge von heute anzeigen (autogrow)     */ 
/* ================================================================== */
IF Komando = 'GETGROUP' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start GETGROUP'
        pos2=pos(' ', UebergabeARG,pos1+1)
        accountname = SUBSTR(UebergabeARG, pos1+1,pos2 - pos1-1)
        accountnametranslate=translate(accountname," ","|")
        groupname = SUBSTR(UebergabeARG, pos2+1,LENGTH(UebergabeARG) - pos2)
        groupnametranslate=translate(groupname," ","|")
        if Globals.!Log='YES' then do
                CALL LINEOUT Globals.!LOGFile,'->   Accountname          = ' || accountname
                CALL LINEOUT Globals.!LOGFile,'->   Accountnametranslate = ' || accountnametranslate
                CALL LINEOUT Globals.!LOGFile,'->   Groupname            = ' || groupname
                CALL LINEOUT Globals.!LOGFile,'->   Groupnametranslate   = ' || groupnametranslate
        end

       /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Anzeige der Gruppen von ' || accountnametranslate || '</A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Show Groups from ' || accountnametranslate || '</A></td>'
        end
        say '   </tr>'
        say '</table>'

        groupname_bak=groupname
        groupnametranslate_bak=groupnametranslate

        /* Tabelle mit den Gruppen erstellen */
        say '<table align=center width=80% border="2" cellspacing="2" cellpadding="2">'
        rc=SysFileTree(Globals.!PBMMaildataPath || '\' || accountnametranslate || '\' || groupnametranslate || '\*.*', 'group', 'DT', '*+***')
        /* Die Gruppen werden nach Name sotiert (a->z) angezeigt. */
        if group.0 > 0 then do
                Call SysStemSort "group.", "A","I",,,24,1000
                do i=1 to group.0
                        /* nur den Groupnamen anzeigen */
                        pos1=lastpos('\', group.i)
                        groupname=SUBSTR(group.i, pos1+1,LENGTH(group.i) - pos1)
                        groupnametranslate=translate(groupname,"|"," ")
                        if Globals.!Log='YES' then do
                                CALL LINEOUT Globals.!LOGFile,'->   Group.' || i ||'            = ' || group.i
                                CALL LINEOUT Globals.!LOGFile,'->   Groupname          = ' || groupname
                                CALL LINEOUT Globals.!LOGFile,'->   Groupnametranslate = ' || groupnametranslate
                        end
                        /*PrÅfen ob Mails von heute vorhanden sind*/
                        rc=SysFileTree(Globals.!PBMMaildataPath || '\' || accountnametranslate || '\' || groupnametranslate_bak || '\' || groupname || '\*.POP', 'email', 'FT','*****')
                        /* Die mails werden nach Datum sotiert neuste zuerst. */
                        if email.0 > 0 then do
                                Call SysStemSort "email.", "D","I",,,1,15
                                Dateidatum=SUBSTR(email.1,1,pos('/', email.1,1)+5)
                        end

                        /* Umlaute und Sonderzeichen ersetzen, */
                        zeile=groupname
                        CALL HTML
                        CALL UMLAUTE
                        groupname=zeile
                        /*wenn Mails von heute vorhanden sind, dann (@) */
                        if Dateidatum = dateo & email.0 > 0 then
                                groupname='(@)'||groupname
                        /* und mit link anzeigen */
                        say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
                        say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETGROUP?' || accountname || '?' || groupname_bak || '/' || groupnametranslate || '>' || groupname || '</A></td>'
                        say '   </tr>'
                end
        end
        say '</table>'
        groupname=groupname_bak
        groupnametranslate=groupnametranslate_bak

        say '<hr size=1 noshade>'
        /*Lesen des Verzeichnisses mit allen Mails*/
        rc=SysFileTree(Globals.!PBMMaildataPath || '\' || accountnametranslate || '\' || groupnametranslate || '\*.POP', 'email', 'FT','*****')
        /* Die Accounts werden nach Datum sotiert angezeigt neuste zuerst. */
        if email.0 > 0 then
                Call SysStemSort "email.", "A","I",,,1,15

        i=email.0
        emailstart=1
        if i > Globals.!Emailmax then do
                emailstart=i-Globals.!Emailmax
                Dateidatum=SUBSTR(email.emailstart,1,pos('/', email.i,1)+5)
                Dateidatum=TRANSLATE(Dateidatum,'0',' ')
                DO WHILE (Dateidatum = dateo)
                   Globals.!Emailmax= Globals.!Emailmax + 1
                   emailstart=i-Globals.!Emailmax
                   Dateidatum=SUBSTR(email.emailstart,1,pos('/', email.i,1)+5)
                   Dateidatum=TRANSLATE(Dateidatum,'0',' ')
                end
        end
                   Globals.!Emailmax= Globals.!Emailmax - 1
                   emailstart=i-Globals.!Emailmax
        emails=Globals.!Emailmax + 1
        if email.0 = 0 then
	emails=0
        if Globals.!Lang='GE' then
                say ' Liste der letzten ' || emails || ' Emails im Account : ' || accountnametranslate || ' - ' || groupnametranslate || '                        (' || email.0 || ' Mails) <BR>'
        if Globals.!Lang='EN' then
                say ' List of last ' || emails || ' Emails in Account : ' || accountnametranslate || ' - ' || groupnametranslate || '                        (' || email.0 || ' Mails) <BR>'
        say '<hr size=1 noshade>'

        /* Tabelle mit den Emails erstellen */
        say '<table align=center width=100% border="2" cellspacing="2" cellpadding="2">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><b>Betreff :</b></td>'
                say '      <td align=center><b>Absender :</b></td>'
                say '      <td align=center><b>Datum :</b></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><b>Subject :</b></td>'
                say '      <td align=center><b>From :</b></td>'
                say '      <td align=center><b>Date :</b></td>'
        end
        do emailcount=emailstart to email.0
                /*nur das Subjekt und nicht den Emailnamen anzeigen*/
                pos1=lastpos('\', email.i)+1
                emailname=SUBSTR(email.i, pos1,LENGTH(email.i) - pos1+1)
                Dateiname=Globals.!PBMMaildataPath || '\' || accountnametranslate || '\' || groupnametranslate || '\' || emailname
                Dateidatum=SUBSTR(email.i,1,pos('/', email.i,1)+5)
                Dateidatum=TRANSLATE(Dateidatum,'0',' ')
                if Globals.!Log='YES' then do
                        CALL LINEOUT Globals.!LOGFile,'->   Email.' || i ||'              = ' || email.i
                        CALL LINEOUT Globals.!LOGFile,'->   Emailname            = ' || emailname
                        CALL LINEOUT Globals.!LOGFile,'->   Dateidatum           = ' || Dateidatum
                end

                /* Lesen der Mail, ab jetzt wird die Mail-Kopf im Speicher gehalten */
                xerg=0
                Line = 0
                DO Line=1 by 1 while xerg<3
                        Mail.Line=LINEIN(Dateiname)
                        erg=LINES(Dateiname)
                        if erg=0 then
                                xerg=3
                        ZeileUPPER=TRANSLATE(Mail.Line,tabout,taborg)
                        if pos('SUBJECT:',ZeileUPPER,1) > 0 then
                                xerg=xerg+1
                        if pos('FROM:',ZeileUPPER,1) > 0 then
                                xerg=xerg+1
                        if pos('X-DATERECEIVED:',ZeileUPPER,1) > 0 then
                                xerg=xerg+1
                END
                /*LÑnge der Mail*/
                maillength=Line-1

                xerg = 0
                Line = 0
                DO Line=1 to maillength
                        Zeile=Mail.Line
                        /* Alles in Uppercase*/
                        ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                        /*Wenn =?ISO-8859-1?B? in Zeile dann BASE64*/
                        if pos('=?ISO-8859-1?B?',ZeileUPPER,1) > 0 then do
                                ZeileBASE64=SUBSTR(Zeile,pos('=?ISO-8859-1?B?',ZeileUPPER,1)+15,LENGTH(Zeile)-pos('=?ISO-8859-1?B?',ZeileUPPER,1)-15+1-2)
                                ZeileAnfang=SUBSTR(Zeile,1,pos('=?ISO-8859-1?B?',ZeileUPPER,1)-1)
                                Line = Line + 1
                                Zeile=Mail.Line
                                /* Alles in Uppercase*/
                                ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                                DO while pos('=?ISO-8859-1?B?',ZeileUPPER,1) > 0
                                        ZeileBASE64=ZeileBASE64 || SUBSTR(Zeile,pos('=?ISO-8859-1?B?',ZeileUPPER,1)+15,LENGTH(Zeile)-pos('=?ISO-8859-1?B?',ZeileUPPER,1)-15+1-2)
                                        Line = Line + 1
                                        Zeile=Mail.Line
                                        /* Alles in Uppercase*/
                                        ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                                end
                                /*Umwandeln*/
                                output_file_name='Base64.txt'
                                erg=SysFileDelete(output_file_name)
                                CALL LINEOUT output_file_name,ZeileBASE64
                                erg=STREAM(output_file_name, 'C', "CLOSE")
                                CALL Base64
                                input_file_name='ASCII.TXT'
                                ZeileASCII=LINEIN(input_file_name)
                                erg=STREAM(input_file_name, 'C', "CLOSE")
                                /*und die Zeile wieder zusammenbauen*/
                                Zeile=ZeileAnfang || ZeileASCII
                                ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                                Line=Line-1
                        end
                        if pos('SUBJECT:',ZeileUPPER,1) = 1 then do
                                /* Umlaute und Sonderzeichen ersetzen, */
                                CALL HTML
                                CALL UMLAUTE
                                /*und mit link anzeigen */
                                subjekttranslate=SUBSTR(Zeile,9,LENGTH(Zeile)-9+1)
                                /*wenn die Datei von heute ist, dann (@) */
                                if Dateidatum = dateo then
                                        subjekttranslate='(@)'||subjekttranslate
                                if Globals.!Log='YES' then
                                        CALL LINEOUT Globals.!LOGFile,'->   SubjektStringZeile   = ' || Zeile
                                        CALL LINEOUT Globals.!LOGFile,'->   SubjektString        = ' || subjekttranslate
                                SubjektString='<Font Size="-1"><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETEMAIL?' || accountname || '?' || groupname || '?' || emailname || '>' || i || ':' || subjekttranslate || '</A></Font>'
                                /*fertig*/
                                xerg=xerg+1
                        end
                        if pos('FROM:',ZeileUPPER,1) = 1 then do
                                /* Umlaute und Sonderzeichen ersetzen, */
                                CALL HTML
                                CALL UMLAUTE
                                /*und speichern */
                                fromstring='<Font Size="-1">' || SUBSTR(Zeile,6,LENGTH(Zeile)-6+1)|| '</Font>'
                                if Globals.!Log='YES' then
                                        CALL LINEOUT Globals.!LOGFile,'->   FromstringZeile      = ' || Zeile
                                        CALL LINEOUT Globals.!LOGFile,'->   Fromstring           = ' || SUBSTR(Zeile,6,LENGTH(Zeile)-6+1)
                               /*fertig*/
                                xerg=xerg+1
                        end
                        if pos('X-DATERECEIVED:',ZeileUPPER,1) > 0 then
                                xerg=xerg+1

                        if xerg=3 then do
                                erg=-1
                                say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
                                say '      <td>'||SubjektString||'</td>'
                                say '      <td  align=center>'||fromstring||'</td>'
                                /*Datum in tt/mm/jj */
                                if Globals.!Lang='GE' then do
                                        Dateidatum=TRANSLATE('78345612',Dateidatum,'12345678')
                                end
                                say '      <td  align=center>'||Dateidatum||'</td>'
                        end
                end
                erg=STREAM(Dateiname, 'C', "CLOSE")
                i=i-1
        end
        say '   </tr>'
        say '</table>'
        /* Unterschrift erstellen */
        say '<hr size=1 noshade>'
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Anzeige der Gruppen von ' || accountnametranslate || '</A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Show Groups from ' || accountnametranslate || '</A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End GETGROUP'
END

/* ================================================================== */
/* Anzeigen der Email                                                 */
/* ================================================================== */

IF Komando = 'GETEMAIL' THEN DO
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> Start GETMAIL'
        call BEEP 900,100
        pos2=pos(' ', UebergabeARG,pos1+1)
        pos3=pos(' ', UebergabeARG,pos2+1)
        accountname = SUBSTR(UebergabeARG, pos1+1,pos2 - pos1-1)
        accountnametranslate=translate(accountname," ","|")
        groupname = SUBSTR(UebergabeARG, pos2+1,pos3 - pos2-1)
        groupnametranslate=translate(groupname," ","|")
        /* öberschrift erstellen */
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Anzeige der Gruppen von ' || accountnametranslate || '</A></td>'
                say '      <td align=center><A Href="javascript:history.back()"> Zur&uuml;ck zur Mailliste von ' || accountnametranslate || ' - ' || groupnametranslate || '</A></td>'
                say '      <td align=center><A Href= "javascript:window.print()">Mail drucken</A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Show Groups from ' || accountnametranslate || '</A></td>'
                say '      <td align=center><A Href="javascript:history.back()"> Back to Maillist ' || accountnametranslate || ' - ' || groupnametranslate || '</A></td>'
                say '      <td align=center><A Href= "javascript:window.print()">Print mail</A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        emailname = SUBSTR(UebergabeARG, pos3+1,LENGTH(UebergabeARG) - pos3)
        Dateiname=Globals.!PBMMaildataPath || '\' || accountnametranslate || '\' || groupnametranslate || '\' || emailname
        SchreibenZeile=0
        say '<table align=center width=100% border="2" cellspacing="2" cellpadding="2">'
        say '   <tr bgcolor="'||Globals.!HtmlTableColor||'">'
        say '      <td>'

       /* Lesen der Mail, ab jetzt wird die Mail im Speicher gehalten */
        DO Line=1 by 1 while LINES(Dateiname)
                Mail.Line=LINEIN(Dateiname)
        END
        /*LÑnge der Mail*/
        maillength=Line-1

        /* Die Mail bearbeiten */
        xerg=0
        headerength=0
        SchreibenAkt=1
        ZeileSubjekt=''
        ZeileFrom=''
        ZeileDATE=''
        ZeileDATERECEIVED=''
        /* Header bearbeiten*/
        DO Line=1 to maillength
                Zeile=Mail.Line
                ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                /*Wenn =?ISO-8859-1?B? in Zeile dann BASE64*/
                if pos('=?ISO-8859-1?B?',ZeileUPPER,1) > 0 then do
                        ZeileBASE64=SUBSTR(Zeile,pos('=?ISO-8859-1?B?',ZeileUPPER,1)+15,LENGTH(Zeile)-pos('=?ISO-8859-1?B?',ZeileUPPER,1)-15+1-2)
                        ZeileAnfang=SUBSTR(Zeile,1,pos('=?ISO-8859-1?B?',ZeileUPPER,1)-1)
                        Line = Line + 1
                        Zeile=Mail.Line
                        /* Alles in Uppercase*/
                        ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                        DO while pos('=?ISO-8859-1?B?',ZeileUPPER,1) > 0
                                ZeileBASE64=ZeileBASE64 || SUBSTR(Zeile,pos('=?ISO-8859-1?B?',ZeileUPPER,1)+15,LENGTH(Zeile)-pos('=?ISO-8859-1?B?',ZeileUPPER,1)-15+1-2)
                                Line = Line + 1
                                Zeile=Mail.Line
                                /* Alles in Uppercase*/
                                ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                        end
                        /*Umwandeln*/
                        output_file_name='Base64.txt'
                        erg=SysFileDelete(output_file_name)
                        CALL LINEOUT output_file_name,ZeileBASE64
                        erg=STREAM(output_file_name, 'C', "CLOSE")
                        CALL Base64
                        input_file_name='ASCII.TXT'
                        ZeileASCII=LINEIN(input_file_name)
                        erg=STREAM(input_file_name, 'C', "CLOSE")
                        /*und die Zeile wieder zusammenbauen*/
                        Zeile=ZeileAnfang || ZeileASCII
                        ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                        Line=Line-1
                end
                /*Wenn ein Subjekt angegeben wurde, dieses anzeigen*/
                if SchreibenZeile=0 then do
                        if pos('SUBJECT:',ZeileUPPER,1) = 1 then do
                               /* öberschrift erstellen */
                               /* Umlaute und Sonderzeichen ersetzen, */
                               CALL HTML
                               CALL UMLAUTE
                               ZeileSubjekt=  '         '||Zeile || '<BR>'
                               xerg=xerg+1
                               end
                        if pos('FROM:',ZeileUPPER,1) = 1 then do
                                /* öberschrift erstellen */
                                /* Umlaute und Sonderzeichen ersetzen, */
                                CALL HTML
                                CALL UMLAUTE
                                ZeileFrom='         '|| Zeile || '<BR>'
                                xerg=xerg+1
                        end
                        if pos('DATE:',ZeileUPPER,1) = 1 then do
                                /* öberschrift erstellen */
                                /* Umlaute und Sonderzeichen ersetzen, */
                                CALL HTML
                                CALL UMLAUTE
                                ZeileDATE='         '|| Zeile || '<BR>'
                                xerg=xerg+1
                        end
                        /*Mails mit Text*/
                        if pos('CONTENT-TYPE: TEXT/PLAIN',ZeileUPPER,1) = 1 then do
                                SchreibenAkt=1
                                xerg=xerg+1
                        end

                        /*Mails mit html*/
                        if pos('CONTENT-TYPE: TEXT/HTML',ZeileUPPER,1) = 1 then do
                                SchreibenAkt=2
                                xerg=xerg+1
                        end

                        if pos('X-DATERECEIVED:',ZeileUPPER,1) = 1 then do
                                ZeileDATERECEIVED=  '         '||Zeile || '<BR>'
                                xerg=xerg+1
                        end

                        /*Mails mit n Teilen*/
                        if pos('CONTENT-TYPE: MULTIPART',ZeileUPPER,1) = 1 then do
                                SchreibenZeile=0
                                if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> CONTENT-TYPE: MULTIPART '
                        end 
                        /*Ab jetzt den Trenner suchen*/
                        if SchreibenZeile=0 then do
                        	if LENGTH(Zeile) \=0 then do
                                	/* und jetzt auswerten */
                                        if pos('BOUNDARY',ZeileUPPER,1) > 0 then do
                                	      Globals.!BOUNDARY = SUBSTR(Zeile,pos('BOUNDARY',ZeileUPPER,1)+10,LENGTH(Zeile)-pos('BOUNDARY',ZeileUPPER,1)-10)   
                                              SchreibenZeile=999
                                              if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> MULTIPART BOUNDARY  :' || Globals.!BOUNDARY 
                                        end 
                                end     
                        end
                        
                        if length(Zeile)=0 then
                                xerg=5

                        if xerg = 5 then do
                                say ZeileSubjekt
                                say ZeileFrom
                                say ZeileDATE
                                say ZeileDATERECEIVED
                                say '         <hr size=3>'
                                xerg=0
                                /*Der Text der Mail beginnt immer nach diesen EintrÑgen*/
                                SchreibenZeile=SchreibenAkt
                                headerength=line+1
                                say '         <font face="verdana,arial" >'
                                Zeile=''
                        end
                end
        end

        /*Nachricht beareiten*/
        DO Line=headerength to maillength
                Zeile=Mail.Line
                /*Bonderys nicht anzeigen*/
                if pos(Globals.!BOUNDARY,Zeile,1) > 0 then do
			Line=Line+1
			BOUNDARYFound=1
			Zeile=Mail.Line
                end
                ZeileUPPER=TRANSLATE(Zeile,tabout,taborg)
                /*Nur wenn in der Mail umgeschaltet wird*/
                        /*Mails mit Text*/
                        if pos('CONTENT-TYPE: TEXT/PLAIN',ZeileUPPER,1) = 1 then do
                                SchreibenZeile=1
                                if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> CONTENT-TYPE: TEXT/PLAIN '
                        end 
                        /*Mails mit html*/
                        if pos('CONTENT-TYPE: TEXT/HTML',ZeileUPPER,1) = 1 then do
                                SchreibenZeile=999
                                /* Einstellungen des Users beachten */
                                if Globals.!Show_HTML='YES' then
                                        SchreibenZeile=2
                                if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> CONTENT-TYPE: TEXT/HTML '
                        end
                        /*Mails mit AnhÑngen APPLICATION*/
                        if pos('CONTENT-TYPE: APPLICATION',ZeileUPPER,1) = 1 then do
                                SchreibenZeile=3
				FirstSchreibenZeile=1
                                if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> CONTENT-TYPE: APPLICATION '
                        end
                        /*Mails mit AnhÑngen VIDEO*/
                        if pos('CONTENT-TYPE: VIDEO',ZeileUPPER,1) = 1 then do
                                SchreibenZeile=3
				FirstSchreibenZeile=1
                                if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> CONTENT-TYPE: VIDEO '
                        end


                /*Ab jetzt den Text-Teil anzeigen*/
                if SchreibenZeile=1 then do
                        if LENGTH(Zeile) \=0 then do
                                /* Umlaute und Sonderzeichen ersetzen, */
                                CALL HTML
                                CALL UMLAUTE
                                /* und jetzt ausgeben */
                                if undnocheine=0 then
                                        ZeileOld=''
                                if LASTPOS("=",Zeile) = LENGTH(Zeile) then do
                                        Zeile=SUBSTR(Zeile,1,LENGTH(Zeile)-1)
                                        if LASTPOS("=",Zeile) = LENGTH(Zeile) then do
                                                Zeile=Zeile||'='||'<BR>'
                                                undnocheine=0
                                        end
                                        if LASTPOS("=",Zeile) \= LENGTH(Zeile) then
                                                Zeile=ZeileOld || Zeile
                                                ZeileOld=Zeile
                                                undnocheine=1
                                        end
                                else
                                        undnocheine=0

                                if undnocheine=0 then do
                                        Zeile=ZeileOld || Zeile
                                        ZeileUpper=TRANSLATE(Zeile,tabout,taborg)
                                        posHTTPa = pos("HTTP",ZeileUpper,1)
                                        if posHTTPa \= 0 then do
                                           HTTPeChar= " "
                                           if posHTTPa > 1 then
                                              HTTPeChar=SUBSTR(Zeile,posHTTPa-1,1)
                                           if HTTPeChar="(" then
                                              HTTPeChar=")"
                                           if HTTPeChar="<" then
                                              HTTPeChar=">"
                                           posHTTPe = pos(HTTPeChar,Zeile,posHTTPa+1)
                                           if posHTTPe = 0 then
                                              posHTTPe = LENGTH(Zeile)+1
                                           Zeile=SUBSTR(Zeile,1,posHTTPa-1)||'<A Href='||SUBSTR(Zeile,posHTTPa,posHTTPe-posHTTPa)||'>'||SUBSTR(Zeile,posHTTPa,posHTTPe-posHTTPa)||'</A>'||SUBSTR(Zeile,posHTTPe,length(Zeile)-posHTTPe+1)
                                        end
                                        if posHTTPa = 0 then do
                                           posHTTPa = pos("WWW.",ZeileUpper,1)
                                           if posHTTPa \= 0 then do
                                              HTTPeChar= " "
                                              if posHTTPa > 1 then
                                                 HTTPeChar=SUBSTR(Zeile,posHTTPa-1,1)
                                              if HTTPeChar="(" then
                                                 HTTPeChar=")"
                                              if HTTPeChar="<" then
                                                 HTTPeChar=">"
                                              posHTTPe = pos(HTTPeChar,Zeile,posHTTPa+1)
                                              if posHTTPe = 0 then
                                                 posHTTPe = LENGTH(Zeile)+1
                                              Zeile=SUBSTR(Zeile,1,posHTTPa-1)||'<A Href=HTTP://'||SUBSTR(Zeile,posHTTPa,posHTTPe-posHTTPa)||'>'||SUBSTR(Zeile,posHTTPa,posHTTPe-posHTTPa)||'</A>'||SUBSTR(Zeile,posHTTPe,length(Zeile)-posHTTPe+1)
                                           end
                                        end
                                       say  '             ' || Zeile || '<BR>'
                                end
                        end
                        if LENGTH(Zeile) = 0 then do
                                say '             ' || Zeile || '<BR>'
                                undnocheine=0
                        end
                end

                /*Ab jetzt den html-Teil anzeigen*/
                if SchreibenZeile=2 then do
                        /* Umlaute und Sonderzeichen ersetzen, */
                        CALL UMLAUTE
                        if LENGTH(Zeile) \=0 then do
                                if lastpos('=', Zeile)=LENGTH(Zeile) then
                                        Zeile=SUBSTR(Zeile,1,LENGTH(Zeile)-1)
                                end
                        say Zeile
                        nop
                end

                /*Ab jetzt den Anhangteil bearbeiten*/
                if SchreibenZeile=3 then do
			/*Kopf es Anhangs suchen*/
			if FirstSchreibenZeile=1 then do
				FirstSchreibenZeile=0
                                BOUNDARYFound=0
	                	if pos('NAME=',ZeileUpper,1) > 0 then do
					FileNameAttachment=SUBSTR(Zeile,pos('NAME=',ZeileUpper,1)+6,LENGTH(Zeile)-pos('NAME=',ZeileUpper,1)-6)
                                	if Globals.!Log='YES' then do
					        if ersterdurchlauf=0 then CALL LINEOUT Globals.!LOGFile,'->                End : ' || Line - 2
                                        	CALL LINEOUT Globals.!LOGFile,'-> FileNameAttachment : ' || FileNameAttachment
                                                CALL LINEOUT Globals.!LOGFile,'->              Start : ' || Line + 4
                                        end
                                	say '             Attachment : ' || FileNameAttachment || '<BR>'
                		        ersterdurchlauf=0
                                end
			
			end
			/*Rest bearbeiten*/
                        if BOUNDARYFound=1 then do
                        	if Globals.!Log='YES' then do
                                	CALL LINEOUT Globals.!LOGFile,'->                End : ' || Line - 2
                                end
                        end
                end
        end
        say '         </font>'
        say '      </td>'
        say '   </tr>'
        say '</table>'
        /* Unterschrift erstellen */
        say '<hr size=1 noshade>'
        say '<table align=center width=100% border="6" cellspacing="5" cellpadding="5">'
        say '   <tr>'
        if Globals.!Lang='GE' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Anzeige aller Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Anzeige der Gruppen von ' || accountnametranslate || '</A></td>'
                say '      <td align=center><A Href="javascript:history.back()"> Zur&uuml;ck zur Mailliste von ' || accountnametranslate || ' - ' || groupnametranslate || '</A></td>'
                say '      <td align=center><A Href= "javascript:window.print()">Mail drucken</A></td>'
        end
        if Globals.!Lang='EN' then do
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?READACCOUNT?' || '> Show Accounts</A></td>'
                say '      <td align=center><A Href=' || Globals.!CGI_BIN || Globals.!File || '?GETACCOUNT?' || accountname || '> Show Groups from ' || accountnametranslate || '</A></td>'
                say '      <td align=center><A Href="javascript:history.back()"> Back to Maillist ' || accountnametranslate || ' - ' || groupnametranslate || '</A></td>'
                say '      <td align=center><A Href= "javascript:window.print()">Print mail</A></td>'
        end
        say '   </tr>'
        say '</table>'
        say '<hr size=1 noshade>'
        say '<Font face="verdana,arial"; Size="-2">'||Globals.!myinfo || '    V' || Globals.!ver || ' </Font>'
        if Globals.!Lang='GE' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Erstellt in 'Format(Time('E'),,2)' Sekunden.</Font><BR>'
        if Globals.!Lang='EN' then
                say '<Font face="verdana,arial"; Size="-2"> <A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2> Peter@warp-ecs-owl.de</A> Generated in 'Format(Time('E'),,2)' seconds.</Font><BR>'
        call BEEP 900,100
        if Globals.!Log='YES' then CALL LINEOUT Globals.!LOGFile,'-> End GETMAIL'
END

say '</body></html>'
say ''
return

/* ================================================================== */
/* HTML öbersetzungen in der Email bearbeiten                         */
/* ================================================================== */
HTML:
         STR1=Zeile
         STR1UPPER=TRANSLATE(STR1,tabout,taborg)
         /* HTML eigene Zeichen */
         /* < */
         STR2='<'
         STR3='&lt;'
         CALL STR123
         /* > */
         STR2='>'
         STR3='&gt;'
         CALL STR123
         /* " */
         STR2='"'
         STR3='&quot;'
         CALL STR123
         /*  */
         STR2='=26'
         STR3='&amp;'
         CALL STR123
         Zeile=STR1
         /*  */
         STR2='ISO-8859-1'
         STR3=''
         CALL STR123
         Zeile=STR1
return


/* ================================================================== */
/* Decodes a Base64 file.                                             */
/*                                                                    */
/* Die Daten werden aus der Datei Base64.txt gelesen                  */
/* und in die Datei ASCII.TXT zurÅck geschrieben                      */
/* ================================================================== */
BASE64:
        char_set='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        DO Base64n=0 to 127
                t.Base64n=-1
        END
        DO Base64n=0 to 63
                Base64i=C2D(SUBSTR(char_set,Base64n+1,1))
                t.Base64i=Base64n
        END

        input_file_name='Base64.txt'
        output_file_name='ASCII.TXT'

        Base64i=SysFileDelete(output_file_name)
        input_line=''
        input_line_index=81
        input_eof=0
        DO WHILE (input_eof = 0)
                sextet_num=1
                num_bits=0
                DO WHILE(sextet_num <= 4)
                        DO WHILE((input_eof = 0) & (input_line_index > LENGTH(input_line)))
                                IF LINES(input_file_name) = 0 THEN
                                        input_eof=-1
                                ELSE
                                DO
                                        input_line=LINEIN(input_file_name)
                                        input_line_index=1
                                END
                        END
                        IF input_eof = 0 THEN
                        DO
                                Base64i=C2D(SUBSTR(input_line,input_line_index,1))
                                input_line_index=input_line_index+1
                                t1=t.Base64i
                                IF t1 >= 0 THEN
                                DO
                                        sextet.sextet_num=t1
                                        num_bits=num_bits+6
                                        sextet_num=sextet_num+1
                                END
                        END
                        ELSE
                        DO
                                sextet.sextet_num=0
                                sextet_num=sextet_num+1
                        END
                END
                IF num_bits >= 8 THEN
                DO
                        t1=sextet.1
                        t2=sextet.2
                        CALL CHAROUT output_file_name,D2C(4*t1+t2%16)
                        num_bits=num_bits-8
                END
                IF num_bits >= 8 THEN
                DO
                        t1=sextet.3
                        CALL CHAROUT output_file_name,D2C(16*(t2//16)+(t1%4))
                        num_bits=num_bits-8
                END
                IF num_bits >= 8 THEN
                DO
                        t2=sextet.4
                        CALL CHAROUT output_file_name,D2C(64*(t1//4)+t2)
                END
        END
        erg=STREAM(input_file_name, 'C', "CLOSE")
        erg=STREAM(output_file_name, 'C', "CLOSE")

return

/* ================================================================== */
/* Umlaute und Co in der Email bearbeiten (ISO-8859-1)                */
/* ================================================================== */
UMLAUTE:
                STR1=Zeile
                STR1UPPER=TRANSLATE(STR1,tabout,taborg)
                /* Umlaute und Sonderzeichen ersetzen, */
                if LASTPOS("=2",STR1UPPER) > 0 then do
                        /*  */
                        STR2='=20'
                        STR3='ˇ'
                        CALL STR123
                        /*  */
                        STR2='=21'
                        STR3='!'
                        CALL STR123
                        /*  */
                        STR2='=22'
                        STR3='&quot;'
                        CALL STR123
                        /*  */
                        STR2='=23'
                        STR3='#'
                        CALL STR123
                        /*  */
                        STR2='=24'
                        STR3='$'
                        CALL STR123
                        /*  */
                        STR2='=25'
                        STR3='%'
                        CALL STR123
                        /*  */
                        STR2='=26'
                        STR3='&'
                        CALL STR123
                        /*  */
                        STR2='=27'
                        STR3=' '
                        CALL STR123
                        /* ( */
                        STR2='=28'
                        STR3='('
                        CALL STR123
                        /* ) */
                        STR2='=29'
                        STR3=')'
                        CALL STR123
                        /*  */
                        STR2='=2A'
                        STR3='*'
                        CALL STR123
                        /*  */
                        STR2='=2B'
                        STR3='+'
                        CALL STR123
                        /*  */
                        STR2='=2C'
                        STR3=','
                        CALL STR123
                        /* - */
                        STR2='=2D'
                        STR3='-'
                        CALL STR123
                        /* . */
                        STR2='=2E'
                        STR3='.'
                        CALL STR123
                        /* / */
                        STR2='=2F'
                        STR3='/'
                        CALL STR123
                END
                if LASTPOS("=3",STR1UPPER) > 0 then do
                        /* : */
                        STR2='=30'
                        STR3='0'
                        CALL STR123
                        /* : */
                        STR2='=31'
                        STR3='1'
                        CALL STR123
                        /* : */
                        STR2='=32'
                        STR3='2'
                        CALL STR123
                        /* : */
                        STR2='=33'
                        STR3='3'
                        CALL STR123
                        /* : */
                        STR2='=34'
                        STR3='4'
                        CALL STR123
                        /* : */
                        STR2='=35'
                        STR3='5'
                        CALL STR123
                        /* : */
                        STR2='=36'
                        STR3='6'
                        CALL STR123
                        /* : */
                        STR2='=37'
                        STR3='7'
                        CALL STR123
                        /* : */
                        STR2='=38'
                        STR3='8'
                        CALL STR123
                        /* : */
                        STR2='=39'
                        STR3='9'
                        CALL STR123
                        /* : */
                        STR2='=3A'
                        STR3=':'
                        CALL STR123
                        /* : */
                        STR2='=3B'
                        STR3=';'
                        CALL STR123
                        /* : */
                        STR2='=3C'
                        STR3='&lt;'
                        CALL STR123
                        /* = */
                        STR2='=3D'
                        STR3='='
                        CALL STR123
                        /* : */
                        STR2='=3E'
                        STR3='&gt;'
                        CALL STR123
                        /* : */
                        STR2='=3F'
                        STR3='?'
                        CALL STR123
                end
                        /*  */
                        STR2='=40'
                        STR3='@'
                        CALL STR123
                if LASTPOS("=5",STR1UPPER) > 0 then do
                        /*  */
                        STR2='=5B'
                        STR3='['
                        CALL STR123
                        /*  */
                        STR2='=5C'
                        STR3='\'
                        CALL STR123
                        /*  */
                        STR2='=5D'
                        STR3=']'
                        CALL STR123
                        /*  */
                        STR2='=5E'
                        STR3='^'
                        CALL STR123
                        /*  */
                        STR2='=5F'
                        STR3='_'
                        CALL STR123
                END
                if LASTPOS("=6",STR1UPPER) > 0 then do
                        /*  */
                        STR2='=60'
                        STR3='`'
                        CALL STR123
                END
                if LASTPOS("=7",STR1UPPER) > 0 then do
                        /*  */
                        STR2='=7B'
                        STR3='{'
                        CALL STR123
                        /*  */
                        STR2='=7C'
                        STR3='|'
                        CALL STR123
                        /*  */
                        STR2='=7D'
                        STR3='}'
                        CALL STR123
                        /*  */
                        STR2='=7E'
                        STR3='~'
                        CALL STR123
                END
                if LASTPOS("=A",STR1UPPER) > 0 then do
                        /* . */
                        STR2='=A0'
                        STR3='&nbsp;'
                        CALL STR123
                        /* . */
                        STR2='=A1'
                        STR3='&iexcl;'
                        CALL STR123
                        /* . */
                        STR2='=A2'
                        STR3='&cent;'
                        CALL STR123
                        /* . */
                        STR2='=A3'
                        STR3='&pound;'
                        CALL STR123
                        /* . */
                        STR2='=A4'
                        STR3='&curren;'
                        CALL STR123
                        /* . */
                        STR2='=A5'
                        STR3='&yen;'
                        CALL STR123
                        /* . */
                        STR2='=A6'
                        STR3='&brvbar;'
                        CALL STR123
                        /* . */
                        STR2='=A7'
                        STR3='&sect;'
                        CALL STR123
                        /* . */
                        STR2='=A8'
                        STR3='&uml;'
                        CALL STR123
                        /* . */
                        STR2='=A9'
                        STR3='&copy;'
                        CALL STR123
                        /* . */
                        STR2='=AA'
                        STR3='&ordf;'
                        CALL STR123
                        /* . */
                        STR2='=AB'
                        STR3='&laquo;'
                        CALL STR123
                        /* . */
                        STR2='=AC'
                        STR3='&not;'
                        CALL STR123
                        /* . */
                        STR2='=AD'
                        STR3='&shy;'
                        CALL STR123
                        /* . */
                        STR2='=AE'
                        STR3='reg;'
                        CALL STR123
                        /* . */
                        STR2='=AF'
                        STR3='&macr;'
                        CALL STR123
                END
                if LASTPOS("=B",STR1UPPER) > 0 then do
                        /* . */
                        STR2='=B0'
                        STR3='&deg;'
                        CALL STR123
                        /* . */
                        STR2='=B1'
                        STR3='&plusmn;'
                        CALL STR123
                        /* . */
                        STR2='=B2'
                        STR3='&sup2;'
                        CALL STR123
                        /* . */
                        STR2='=B3'
                        STR3='&sup3;'
                        CALL STR123
                        /* . */
                        STR2='=B4'
                        STR3='&acute;'
                        CALL STR123
                        /* . */
                        STR2='=B5'
                        STR3='&micro;'
                        CALL STR123
                        /* . */
                        STR2='=B6'
                        STR3='&para;'
                        CALL STR123
                        /* . */
                        STR2='=B7'
                        STR3='&middot;'
                        CALL STR123
                        /* . */
                        STR2='=B8'
                        STR3='&cedil;'
                        CALL STR123
                        /* . */
                        STR2='=B9'
                        STR3='&sup1;'
                        CALL STR123
                        /* . */
                        STR2='=BA'
                        STR3='&ordm;'
                        CALL STR123
                        /* . */
                        STR2='=BB'
                        STR3='&raquo;'
                        CALL STR123
                        /* . */
                        STR2='=BC'
                        STR3='&frac14;'
                        CALL STR123
                        /* . */
                        STR2='=BD'
                        STR3='&frac12;'
                        CALL STR123
                        /* . */
                        STR2='=BE'
                        STR3='&frac34;'
                        CALL STR123
                        /* . */
                        STR2='=BF'
                        STR3='&iquest;'
                        CALL STR123
                END
                if LASTPOS("=C",STR1UPPER) > 0 then do
                        /* . */
                        STR2='=C0'
                        STR3='&Agrave;'
                        CALL STR123
                        /* . */
                        STR2='=C1'
                        STR3='&Aacute;'
                        CALL STR123
                        /* . */
                        STR2='=C2'
                        STR3='&Acirc;'
                        CALL STR123
                        /* . */
                        STR2='=C3'
                        STR3='&Atilde;'
                        CALL STR123
                        /* . */
                        STR2='=C4'
                        STR3='&Auml;'
                        CALL STR123
                        /* . */
                        STR2='=C5'
                        STR3='&Aring;'
                        CALL STR123
                        /* . */
                        STR2='=C6'
                        STR3='&AElig;'
                        CALL STR123
                        /* . */
                        STR2='=C7'
                        STR3='&Ccedil;'
                        CALL STR123
                        /* . */
                        STR2='=C8'
                        STR3='&Egrave;'
                        CALL STR123
                        /* . */
                        STR2='=C9'
                        STR3='&Eacute;'
                        CALL STR123
                        /* . */
                        STR2='=CA'
                        STR3='&Eacute;'
                        CALL STR123
                        /* . */
                        STR2='=CB'
                        STR3='&Euml;'
                        CALL STR123
                        /* . */
                        STR2='=CC'
                        STR3='&Igrave;'
                        CALL STR123
                        /* . */
                        STR2='=CD'
                        STR3='&Iacute;'
                        CALL STR123
                        /* . */
                        STR2='=CE'
                        STR3='&Icirc;'
                        CALL STR123
                        /* . */
                        STR2='=CF'
                        STR3='&Iuml;'
                        CALL STR123
                END
                if LASTPOS("=D",STR1UPPER) > 0 then do
                        /* . */
                        STR2='=D0'
                        STR3='&ETH;'
                        CALL STR123
                        /* . */
                        STR2='=D1'
                        STR3='&Ntilde;'
                        CALL STR123
                        /* . */
                        STR2='=D2'
                        STR3='&Ograve;'
                        CALL STR123
                        /* . */
                        STR2='=D3'
                        STR3='&Oacute;'
                        CALL STR123
                        /* . */
                        STR2='=D4'
                        STR3='&Ocirc;'
                        CALL STR123
                        /* . */
                        STR2='=D5'
                        STR3='&Otilde;'
                        CALL STR123
                        /* . */
                        STR2='=D6'
                        STR3='&Ouml;'
                        CALL STR123
                        /* . */
                        STR2='=D7'
                        STR3='&times;'
                        CALL STR123
                        /* . */
                        STR2='=D8'
                        STR3='&Oslash;'
                        CALL STR123
                        /* . */
                        STR2='=D9'
                        STR3='&Ugrave;'
                        CALL STR123
                        /* . */
                        STR2='=DA'
                        STR3='&Uacute;'
                        CALL STR123
                        /* . */
                        STR2='=DB'
                        STR3='&Ucirc;'
                        CALL STR123
                        /* . */
                        STR2='=DC'
                        STR3='&Uuml;'
                        CALL STR123
                        /* . */
                        STR2='=DD'
                        STR3='&Yacute;'
                        CALL STR123
                        /* . */
                        STR2='=DE'
                        STR3='&THORN;'
                        CALL STR123
                        /* . */
                        STR2='=DF'
                        STR3='&szlig;'
                        CALL STR123
                END
                if LASTPOS("=E",STR1UPPER) > 0 then do
                        /* . */
                        STR2='=E0'
                        STR3='&agrave;'
                        CALL STR123
                        /* . */
                        STR2='=E1'
                        STR3='&aacute;'
                        CALL STR123
                        /* . */
                        STR2='=E2'
                        STR3='&acirc;'
                        CALL STR123
                        /* . */
                        STR2='=E3'
                        STR3='&atilde;'
                        CALL STR123
                        /* . */
                        STR2='=E4'
                        STR3='&auml;'
                        CALL STR123
                        /* . */
                        STR2='=E5'
                        STR3='&aring;'
                        CALL STR123
                        /* . */
                        STR2='=E6'
                        STR3='&aelig;'
                        CALL STR123
                        /* . */
                        STR2='=E7'
                        STR3='&ccedil;'
                        CALL STR123
                        /* . */
                        STR2='=E8'
                        STR3='&egrave;'
                        CALL STR123
                        /* . */
                        STR2='=E9'
                        STR3='&eacute;'
                        CALL STR123
                        /* . */
                        STR2='=EA'
                        STR3='&ecirc;'
                        CALL STR123
                        /* . */
                        STR2='=EB'
                        STR3='&euml;'
                        CALL STR123
                        /* . */
                        STR2='=EC'
                        STR3='&igrave;'
                        CALL STR123
                        /* . */
                        STR2='=ED'
                        STR3='&iacute;'
                        CALL STR123
                        /* . */
                        STR2='=EE'
                        STR3='&icirc;'
                        CALL STR123
                        /* . */
                        STR2='=EF'
                        STR3='&iuml;'
                        CALL STR123
                END
                if LASTPOS("=F",STR1UPPER) > 0 then do
                        /* . */
                        STR2='=F0'
                        STR3='&eth;'
                        CALL STR123
                        /* . */
                        STR2='=F1'
                        STR3='&ntilde;'
                        CALL STR123
                        /* . */
                        STR2='=F2'
                        STR3='&ograve;'
                        CALL STR123
                        /* . */
                        STR2='=F3'
                        STR3='&oacute;'
                        CALL STR123
                        /* . */
                        STR2='=F4'
                        STR3='&ocirc;'
                        CALL STR123
                        /* . */
                        STR2='=F5'
                        STR3='&otilde;'
                        CALL STR123
                        /* . */
                        STR2='=F6'
                        STR3='&ouml;'
                        CALL STR123
                        /* . */
                        STR2='=F7'
                        STR3='&divide;'
                        CALL STR123
                        /* . */
                        STR2='=F8'
                        STR3='&oslash;'
                        CALL STR123
                        /* . */
                        STR2='=F9'
                        STR3='&ugrave;'
                        CALL STR123
                        /* . */
                        STR2='=FA'
                        STR3='&uacute;'
                        CALL STR123
                        /* . */
                        STR2='=FB'
                        STR3='&ucirc;'
                        CALL STR123
                        /* . */
                        STR2='=FC'
                        STR3='&uuml;'
                        CALL STR123
                        /* . */
                        STR2='=FD'
                        STR3='&yacute;'
                        CALL STR123
                        /* . */
                        STR2='=FE'
                        STR3='&thorn;'
                        CALL STR123
                        /* . */
                        STR2='=FF'
                        STR3='&yuml;'
                        CALL STR123
                END
                /* ’ */
                STR2='=80'
                STR3='&euro;'
                CALL STR123
                /*  */
                STR2='=84'
                STR3=''
                CALL STR123
                /*  */
                STR2='=93'
                STR3=''
                CALL STR123
                /* Sondersachen */
                /* RETURN2 */
                STR2='=0A'
                STR3=''
                CALL STR123
                /* RETURN3 */
                STR2='=0D'
                STR3='<BR>'
                CALL STR123
                /* =? */
                STR2='=?'
                STR3=''
                CALL STR123
                /* ?= */
                STR2='?='
                STR3=''
                CALL STR123
                /* ?Q? */
                STR2='?Q?'
                STR3='ˇ'
                CALL STR123
                /* Fertig Umlaute und Sonderzeichen ersetzen, */
                Zeile=STR1
return

STR123:
        posRepStr1=pos(STR2,STR1UPPER,1)
        do while posRepStr1\=0
                if posRepStr1\=0 then do
                        if STR3='ˇ' then
                                STR1=SUBSTR(STR1,1,posRepStr1-1)|| ' ' || SUBSTR(STR1,posRepStr1+LENGTH(STR2),LENGTH(STR1)-posRepStr1-LENGTH(STR2)+1)
                        else do
                                if STR3='' then
                                        STR1=SUBSTR(STR1,1,posRepStr1-1)||SUBSTR(STR1,posRepStr1+LENGTH(STR2),LENGTH(STR1)-posRepStr1-LENGTH(STR2)+1)
                                else
                                        STR1=SUBSTR(STR1,1,posRepStr1-1)||STR3||SUBSTR(STR1,posRepStr1+LENGTH(STR2),LENGTH(STR1)-posRepStr1-LENGTH(STR2)+1)
                        end
                end
                STR1UPPER=TRANSLATE(STR1,tabout,taborg)
                posRepStr1=pos(STR2,STR1UPPER,1)
        end
return

/* ================================================================== */
/* Wenn Fehler :(( dann anzeigen                                      */
/* ================================================================== */
Fehler:
        if Globals.!Log='YES' then do
                CALL LINEOUT Globals.!LOGFile,'Version......: ' || Globals.!ver
                CALL LINEOUT Globals.!LOGFile,'Linenumber...: ' || sigl
                CALL LINEOUT Globals.!LOGFile,'Linetext.....: ' || sourceline(sigl)
                CALL LINEOUT Globals.!LOGFile,'Errorcode....: ' || rc
                CALL LINEOUT Globals.!LOGFile,'Errortext....: ' || errortext(rc)
                CALL LINEOUT Globals.!LOGFile,'OS-Version...: ' || SysVersion()
                CALL LINEOUT Globals.!LOGFile,'Rexx-Version.: ' || SysUtilVersion()
                    CALL LINEOUT Globals.!LOGFile,'XtraRexx.....: ' || XtraVersion()
                erg=STREAM(Globals.!LOGFile, 'C', "CLOSE")
        end
        say '<BR>'
        say '<hr size=1 noshade>'
        say '-Hoops-'
        if Globals.!Lang='GE' then
                say '<font color="#FF0000">Senden Sie diesen Fehlerreport und Email-Datei an :</font><BR>'
        if Globals.!Lang='EN' then
                say '<font color="#FF0000">Send this bug report and the Email-File to :</font><BR>'
        say '<A Href=mailto:Peter@warp-ecs-owl.de?subject=PolarbarWeb/2%20Error> (Peter L&uuml;ersen) Peter@warp-ecs-owl.de</A><BR>'
        say 'Subject : PolarbarWeb/2 Error'
        say '<hr size=1 noshade>'
        say 'Version......: ' || Globals.!ver||'<BR>'
        say 'Linenumber...: ' || sigl||'<BR>'
        say 'Linetext.....: ' || sourceline(sigl)||'<BR>'
        say 'Errorcode....: ' || rc||'<BR>'
        say 'Errortext....: ' || errortext(rc)||'<BR>'
        say '<BR>'
        say 'OS-Version...: ' || SysVersion()||'<BR>'
        say 'Rexx-Version.: ' || SysUtilVersion() || '<BR>'
        say 'XtraRexx.....: ' || XtraVersion() || '<BR>'
        say '<hr size=1 noshade>'
exit

/*********************************************************************/
getEnv:PROCEDURE
RETURN VALUE(ARG(1),, 'OS2ENVIRONMENT')

/*********************************************************************/
putEnv:PROCEDURE
RETURN VALUE(ARG(1), ARG(2), 'OS2ENVIRONMENT')


