create procedure [dbo].[wOPPlataRM](@sesiune varchar(50), @parXML xml) as
begin            
	declare @tert varchar(20), @factura varchar(20), @valtotala float, @dataplatii datetime,
		@valuta varchar(3), @curs float, @valoarevaluta float, @sumavaluta float,
		@contcasa varchar(40), @sumalei float, @chitanta varchar(20), @contfactura varchar(40),
		@lm varchar(9), @comanda varchar(20), @userASIS varchar(20), @nrpoz int, @suma float
	 --        
	set @tert=isnull(@parXML.value('(parametri/@tert)[1]','varchar(20)'),'')
	set @factura=isnull(@parXML.value('(parametri/@factura)[1]','varchar(20)'),'')
	set @valtotala=isnull(@parXML.value('(parametri/@valtotala)[1]','decimal(10,2)'),'')
	set @dataplatii=isnull(@parXML.value('(parametri/@dataplatii)[1]','datetime'),isnull(@parXML.value('(parametri/@datafacturii)[1]','datetime'),''))
	set @valuta=isnull(@parXML.value('(parametri/@valuta)[1]','varchar(3)'),'')
	set @curs=isnull(@parXML.value('(parametri/@curs)[1]','decimal(12,4)'),'')
	set @valoarevaluta=isnull(@parXML.value('(parametri/@valoarevaluta)[1]','decimal(12,4)'),'')
	set @contfactura=isnull(@parXML.value('(parametri/@contfactura)[1]','varchar(40)'),'')
	set @lm=isnull(@parXML.value('(parametri/@lm)[1]','varchar(9)'),'')
	set @comanda=isnull(@parXML.value('(parametri/@comanda)[1]','varchar(20)'),'')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	--        
     
	set @nrpoz=ISNULL((select MAX(numar_pozitie) from pozplin where subunitate='1' and cont=@contcasa and data=@dataplatii),0)
	set @nrpoz=@nrpoz+1
	--  
 
	set @contcasa=isnull(@parXML.value('(parametri/@contcasa)[1]','varchar(40)'),'')
	declare @utilizator varchar(20),@contproprietate varchar(40)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	set @contProprietate=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod=@userASiS and cod_proprietate='CONTPLIN'), '')
	print @contProprietate
	if isnull(@contcasa,'')=''
		set @contcasa=@contproprietate

	if @valuta<>''
		set @suma=isnull(@parXML.value('(parametri/@valoarevaluta)[1]','decimal(10,2)'),0)
	else
		set @suma=isnull(@parXML.value('(parametri/@valtotala)[1]','decimal(10,2)'),0)

	set @chitanta=isnull(@parXML.value('(parametri/@numar)[1]','varchar(20)'),'')     
	 --Date introduse gresit        
	if @contcasa=''
		raiserror('Introduceti contul de casa! Nu s-a inregistrat plata!',16,1)      
	else if @chitanta=''
		raiserror('Introduceti numarul de chitanta! Nu s-a inregistrat plata!',16,1)
	 --else if @suma<>0
	 -- raiserror('Platiti fie in lei fie in valuta! Nu s-a inregistrat plata!',16,1)
	else if @suma=0
		raiserror('Introduceti o valoare pentru incasare! Nu s-a inregistrat plata!',16,1)
	 --Factura in lei, suma in lei=0 sau factura in valuta, suma in valuta=0
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma=0
		raiserror('Factura e in lei, deci introduceti doar suma in lei! Nu s-a inregistrat plata!',16,1)
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma=0
		raiserror('Factura e in valuta, deci introduceti doar suma in valuta! Nu s-a inregistrat plata!',16,1)
	 --Cont lei sau valuta
	 --Factura in lei sau valuta, incasare peste valoarea facturii
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma<>0 and @valtotala<@suma
		raiserror('Nu puteti plati mai mult decat valoarea facturii! Nu s-a inregistrat plata!',16,1)
	else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma<>0 and @valoarevaluta<@suma   
		raiserror('Nu puteti plati, in valuta, mai mult decat valoarea facturii! Nu s-a inregistrat plata!',16,1)
	 --Mai exista o incasare pe aceasta factura
	else if exists (select * from pozplin where subunitate='1' and cont=@contcasa and data=@dataplatii and Plata_incasare='PF' and tert=@tert and Factura=@factura and Suma<>0)
		raiserror('S-a platit deja aceasta factura! Nu mai puteti sa o platiti decat la Plati/Incasari! Nu s-a inregistrat plata!',16,1)
	 --Inregistrare incasare
	else if @curs=0 and @valuta='' and @valoarevaluta=0 and @suma<>0
		begin
			insert into pozplin (Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,Valuta,Curs,Suma_valuta,Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,
			Loc_de_munca,Comanda,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Cont_dif,Suma_dif,Achit_fact,Jurnal)
			values ('1',@contcasa,@dataplatii,@chitanta,'PF',@tert,@factura,@contfactura,@suma,'',0,0,0,'24',0,
			'Plata factura',@lm,@comanda,@userASIS,convert(datetime, convert(char(10), getdate(), 104), 104),
			RTrim(replace(convert(char(8), getdate(), 108), ':', '')),@nrpoz,'',0,0,'')
			--raiserror('S-a inregistrat plata in lei!',16,1)
			select 'S-a inregistrat plata in lei!' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje')
		end        
	 else if @curs<>0 and @valuta<>'' and @valoarevaluta<>0 and @suma<>0
	 begin
		insert into pozplin (Subunitate,Cont,Data,Numar,Plata_incasare,Tert,Factura,Cont_corespondent,Suma,Valuta,Curs,Suma_valuta,
		Curs_la_valuta_facturii,TVA11,TVA22,Explicatii,Loc_de_munca,Comanda,Utilizator,Data_operarii,Ora_operarii,Numar_pozitie,Cont_dif,
		Suma_dif,Achit_fact,Jurnal)
		values ('1',@contcasa,@dataplatii,@chitanta,'PF',@tert,@factura,@contfactura,
		round(@suma*@curs,2),@valuta,@curs,@suma,@curs,24,0,'Plata factura',@lm,@comanda,@userASIS,
		convert(datetime, convert(char(10), getdate(), 104), 104),RTrim(replace(convert(char(8), getdate(), 108), ':', '')),@nrpoz,'765',0,@suma,'')
  
	   --raiserror('S-a inregistrat plata in valuta!',16,1)
		select 'S-a inregistrat plata in valuta!' as textMesaj, 'Info' as titluMesaj for xml raw, root('Mesaje')
	 end
	 else
		raiserror('Nu s-a inregistrat plata! Verifica daca ai introdus corect datele incasarii si reia operatia!',16,1)
end 
