="documente "+max(iif(Fields!parametru.Value="@rIntervalDocFinanciare",Fields!valoare.Value,""), "par")
+iif(Parameters!cTert.Value<>"",vbcrlf+"pe tertul "+trim(Parameters!cTert.Value)+
          " ("+max(iif(Fields!parametru.Value="@tert",Fields!valoare.Value,""), "par")+")","")
		  +iif(not isnothing(Parameters!punctLivrare.Value) and not isnothing(Parameters!cTert.Value)
					and Parameters!cFurnBenef.Value="B"
				,vbcrlf+"punctul de livrare "+trim(Parameters!punctLivrare.Value)+
				" ("+max(iif(Fields!parametru.Value="@punctLivrare",Fields!valoare.Value,""), "par")+")","")
          +iif(Parameters!cFactura.Value<>"",vbcrlf+"factura "+trim(Parameters!cFactura.Value),"")
          +iif(trim(Parameters!cContTert.Value)<>"",vbcrlf+"contul de tert "+trim(Parameters!cContTert.Value)+
          " ("+max(iif(Fields!parametru.Value="@cont",Fields!valoare.Value,""), "par")+")","")
          +iif(cstr(Parameters!Soldmin.Value)<>"",vbcrlf+"cu soldul minim "+trim(cstr(Parameters!Soldmin.Value)),"")
          +iif(cstr(Parameters!grupa.Value)<>"",vbcrlf+"grupa de terti "+trim(cstr(Parameters!grupa.Value))+
          " ("+max(iif(Fields!parametru.Value="@grupaTert",Fields!valoare.Value,""), "par")+")","")
          +iif(cstr(Parameters!indicator.Value)<>"",vbcrlf+"indicatorul "+trim(cstr(Parameters!indicator.Value))+
          " ("+max(iif(Fields!parametru.Value="@indicator",Fields!valoare.Value,""), "par")+")","")
          +iif(cstr(Parameters!locm.Value)<>"",vbcrlf+"locul de munca "+trim(cstr(Parameters!locm.Value))+
          " ("+max(iif(Fields!parametru.Value="@locm",Fields!valoare.Value,""), "par")+")","")

          +iif(not isnothing(Parameters!dDataFactJos.Value) or not isnothing(Parameters!dDataFactSus.Value)," emise ","")
          +iif(not isnothing(Parameters!dDataFactJos.Value) and isnothing(Parameters!dDataFactSus.Value),"dupa ","")
          +iif(isnothing(Parameters!dDataFactJos.Value) and not isnothing(Parameters!dDataFactSus.Value),"inainte de ","")
          +iif(not isnothing(Parameters!dDataFactJos.Value) and not isnothing(Parameters!dDataFactSus.Value),"intre "
          +format(Parameters!dDataFactJos.Value,"dd/MM/yyyy")+" si "+format(Parameters!dDataFactSus.Value,"dd/MM/yyyy"),
          format(Parameters!dDataFactJos.Value,"dd/MM/yyyy")+format(Parameters!dDataFactSus.Value,"dd/MM/yyyy"))
          +iif(not isnothing(Parameters!dDataScadJos.Value) or not isnothing(Parameters!dDataScadSus.Value)," scadente ","")
          +iif(not isnothing(Parameters!dDataScadJos.Value) and isnothing(Parameters!dDataScadSus.Value),"dupa ","")
          +iif(isnothing(Parameters!dDataScadJos.Value) and not isnothing(Parameters!dDataScadSus.Value),"inainte de ","")
          +iif(not isnothing(Parameters!dDataScadJos.Value) and not isnothing(Parameters!dDataScadSus.Value),"intre "
          +format(Parameters!dDataScadJos.Value,"dd/MM/yyyy")+" si "+format(Parameters!dDataScadSus.Value,"dd/MM/yyyy"),
          format(Parameters!dDataScadJos.Value,"dd/MM/yyyy")+format(Parameters!dDataScadSus.Value,"dd/MM/yyyy"))
          +iif(isnothing(Parameters!FSoldData.Value),"",vbcrlf+"facturi pe sold la "+format(Parameters!FSoldData.Value,"dd/MM/yyyy"))
          +switch(Parameters!tipdoc.Value="X",vbcrlf+"facturi si efecte",Parameters!tipdoc.Value="F","",Parameters!tipdoc.Value="E",vbcrlf+"doar efecte")
          
          +max(iif(Fields!parametru.Value="@propGestiune",vbcrlf+Fields!valoare.Value,""),"par")
          +max(iif(Fields!parametru.Value="@propLocm",vbcrlf+Fields!valoare.Value,""),"par")