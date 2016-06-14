--declare @p2 xml
--set @p2=convert(xml,N'<parametri subunitate="1" tip="AP" numar="9430064" numarf="9430064" data="02/28/2012" dataf="02/28/2012" dengestiune="GESTIUNE PCT LUCRU NT" gestiune="211" dentert="ELECTRIFICARE CFR S.A." tert="16828396" factura="9430064" contract="" denlm="MARKETING - Filiala PN" lm="1MKT19" dencomanda="" comanda="                    " indbug="                    " gestprim="" dengestprim="" punctlivrare="" denpunctlivrare="" valuta="" curs="0.0000" valoare="425.00" tva11="0.00" tva22="102.00" tvatotala="102.00" valtotala="527.00" valoarevaluta="0.00" totalvaloare="527.00" categpret="4" dencatpret="LISTA MAGAZIN" facturanesosita="0" aviznefacturat="1" cotatva="0.00" discount="0.00" sumadiscount="4.00" tiptva="0" denTiptva="0-TVA Colectat" explicatii="" numardvi="" proforma="0" tipmiscare="8" contfactura="418.0" dencontfactura="418.0-Clienti-facturi de intocmit" contcorespondent="607.1" dencontcorespondent="Cheltuieli privind marfuri en-gros" contvenituri="707.1" dencontvenituri="Venituri din vinz.de marfuri engros" datafacturii="02/28/2012" datascadentei="02/28/2012" zilescadenta="0" jurnal="" numarpozitii="1" valamcatprimitor="0" numedelegat="" seriabuletin="" numarbuletin="" eliberat="" mijloctp="" nrmijloctp="" dataexpedierii="01/01/1901" oraexpedierii="000000" observatii="" punctlivareexped="" contractcor="" detalii="" stare="3" denStare="Operat" culoare="#000000" _nemodificabil="0" chitanta="" sumalei="300" contcasa="5311.2" utilizator="MARIUS" tipMacheta="D" codMeniu="DO" TipDetaliere="AP" subtip="IB" AIR="1" inXML="1"/>')
--exec wOPIncasare @sesiune='083D2A0086836',@parXML=@p2
--GO
ALTER procedure [dbo].[wOPIncasare](@sesiune varchar(50), @parXML xml) as             
begin try           
	declare @tert varchar(20), @factura varchar(20), @valtotala float, @datafacturii datetime,         
		@valuta varchar(3), @curs float, @valoarevaluta float, @sumavaluta float,         
		@contcasa varchar(13), @sumalei float, @numar varchar(20), @contfactura varchar(13),         
		@lm varchar(9), @comanda varchar(20), @userASIS varchar(20), @nrpoz int, @suma float, @chitanta varchar(20)
	-- 
	set @tert=isnull(@parXML.value('(parametri/@tert)[1]','varchar(20)')      ,'')    
	set @factura=isnull(@parXML.value('(parametri/@factura)[1]','varchar(20)')        ,'')    
	set @valtotala=isnull(@parXML.value('(parametri/@valtotala)[1]','decimal(10,2)')       ,'')     
	set @datafacturii=isnull(@parXML.value('(parametri/@data)[1]','datetime')  ,'')          
	set @valuta=isnull(@parXML.value('(parametri/@valuta)[1]','varchar(3)')        ,'')    
	set @curs=isnull(@parXML.value('(parametri/@curs)[1]','decimal(12,4)')        ,'')    
	set @valoarevaluta=isnull(@parXML.value('(parametri/@valoarevaluta)[1]','decimal(12,4)'),'')    
	set @contfactura=isnull(@parXML.value('(parametri/@contfactura)[1]','varchar(13)'),'')        
	set @lm=isnull(@parXML.value('(parametri/@lm)[1]','varchar(9)'),'')         
	set @comanda=isnull(@parXML.value('(parametri/@comanda)[1]','varchar(20)'),'')
	set @chitanta=isnull(@parXML.value('(parametri/@chitanta)[1]','varchar(20)'),'')     
	set @sumalei=isnull(@parXML.value('(parametri/@sumalei)[1]','decimal(10,2)')       ,'')    
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
 	--        
	 
	set @nrpoz=ISNULL((select MAX(numar_pozitie) from pozplin where subunitate='1' and cont=@contcasa and data=@datafacturii),0)        
	set @nrpoz=@nrpoz+1        
 
	set @contcasa=isnull(@parXML.value('(	parametri/@contcasa)[1]','varchar(13)'),'')        
	if @valuta<>''
		set @suma=@valoarevaluta
	else
		if @sumalei=0
			set @suma=@valtotala
		else set @suma=@sumalei
	    
	set @numar=isnull(@parXML.value('(parametri/@numar)[1]','varchar(20)'),'')          
	--set @chitanta=(case when @numar<>@factura then @chitanta else @numar end)
	set @chitanta=(case when @chitanta='' then @numar else @chitanta end)
	--Date introduse gresit
	if @chitanta=''
		raiserror ('Introduceti numarul de chitanta pentru acele cazuri in care numarul difera de factura!Nu s-a inregistrat incasarea!',16,1)        
	else 
	if @contcasa=''        
		raiserror('Introduceti contul de casa! Nu s-a inregistrat incasarea!',16,1)        
	--else if @numar=''         
		--raiserror('Introduceti numarul de chitanta! Nu s-a inregistrat incasarea!',16,1)        
	if not exists (select 1 from conturi where cont=@contcasa and Are_analitice=0)
		raiserror('Contul introdus nu se afla in planul de conturi/sau are analitice!Nu s-a inregistrat incasarea!',16,1)
	 --else if @suma<>0   
		-- raiserror('Platiti fie in lei fie in valuta! Nu s-a inregistrat incasarea!',16,1)        
	else if @suma=0   
		raiserror('Introduceti o valoare pentru incasare! Nu s-a inregistrat incasarea!',16,1)         
	--Factura in lei, suma in lei=0 sau factura in valuta, suma in valuta=0        
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma=0        
		raiserror('Factura e in lei, deci introduceti doar suma in lei! Nu s-a inregistrat incasarea!',16,1)        
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma=0        
		raiserror('Factura e in valuta, deci introduceti doar suma in valuta! Nu s-a inregistrat incasarea!',16,1)        
	--Cont lei sau valuta        
	else if substring(@contcasa,1,4) not in ('5314','5125')  and @curs<>0 and @valuta<>'' and @valoarevaluta<>0         
		raiserror('Factura e in valuta, deci contul de casa trebuie sa fie 5314 / 5125 sau analitice ale lui! Nu s-a inregistrat incasarea!',16,1)        
	else if substring(@contcasa,1,4)not in ('5311','5125') and @curs=0 and @valuta='' and @valoarevaluta=0 and @valtotala<>0        
		raiserror('Factura e in lei, deci contul de casa trebuie sa fie 5311 / 5125 sau analitice ale lui! Nu s-a inregistrat incasarea!',16,1)        
	--Factura in lei sau valuta, incasare peste valoarea facturii        
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma<>0 and @valtotala<@suma        
		raiserror('Nu puteti plati mai mult decat valoarea facturii! Nu s-a inregistrat incasarea!',16,1)        
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma<>0 and @valoarevaluta<@suma        
		raiserror('Nu puteti plati, in valuta, mai mult decat valoarea facturii! Nu s-a inregistrat incasarea!',16,1)          
	--Mai exista o incasare pe aceasta factura        
	else if exists (select * from pozplin where subunitate='1' and data=@datafacturii and Plata_incasare='IB' and tert=@tert and Factura=@factura and Suma<>0)        
		raiserror('S-a incasat deja aceasta factura! Nu mai puteti sa o incasati decat la Plati/Incasari! Nu s-a inregistrat incasarea!',16,1)          
	--Inregistrare incasare     
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma<>0        
	begin 
		insert into pozplin (Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,  
			Loc_de_munca,Comanda,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal)  
		values ('1',@contcasa,@datafacturii,(case when @numar<>@factura then @numar else @chitanta end),'IB',@tert,@factura,@contfactura,@suma,'',0,0,0,'24',0,    
			'Incasare pe loc din AP sau AS',@lm,@comanda,@userASIS,convert(datetime, convert(char(10), getdate(), 104), 104),    
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')),@nrpoz,'',0,0,'')        
	   --raiserror('S-a inregistrat incasarea in lei!',16,1)        
		select 'S-a inregistrat incasarea in lei!' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje')        
	end        
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma<>0        
	begin
		insert into pozplin (Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,Valuta,Curs,Suma_valuta,  
			Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Cont_dif,  
			Suma_dif,Achit_fact,Jurnal)   
		values ('1',@contcasa,@datafacturii,@chitanta,'IB',@tert,@factura,@contfactura,    
			@valtotala,@valuta,@curs,@suma,@curs,24,0,'Incasare pe loc din AP sau AS',@lm,@comanda,@userASIS,    
			convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),@nrpoz,'765',0,@suma,'')        
		--raiserror('S-a inregistrat incasarea in valuta!',16,1)        
		select 'S-a inregistrat incasarea in valuta!' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje')        
	end           
	else           
		raiserror('Nu s-a inregistrat incasarea! Verifica daca ai introdus corect datele incasarii si reia operatia!',16,1)            
end try
begin catch 
    declare @eroare varchar(200) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
