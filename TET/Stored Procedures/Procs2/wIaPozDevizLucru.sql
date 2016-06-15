--***

create procedure wIaPozDevizLucru @sesiune varchar(50), @parXML XML
as
Declare @nrdeviz varchar(100), @doc xml, @cautare varchar(100) 
	set @nrdeviz = isnull(@parXML.value('(/row/@nrdeviz)[1]','varchar(100)'),'')
	set @cautare = '%'+replace(ISNULL(@parXML.value('(/row/@_cautare)[1]','varchar(100)'),'%'),' ','%')+'%'
	
	set @doc=(
	select 
		(case when pp.tip='P' then 'Piese' when pp.tip='M' then 'Manopera' when pp.tip='R' then 
			'Refacturari' when pp.tip='S' then 'Servicii prestate' when pp.tip='G' then 'Grupe de piese' 
			else 'Autovehicule' end) as denumire,
		(select top 100
		    'QE' /*RTRIM(p.Tip)*/ as tip, --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			/*'D'+*/RTRIM(pp.tip) as subtip, 
			RTRIM(p.Cod_deviz) as nrdeviz, 
			isnull(p.Pozitie_articol, 0) as pozitiearticol, 
			RTRIM(p.Tip_resursa) as tipresursa, 
			RTRIM(p.cod) as cod,
			(case	when Tip_resursa='M' then RTRIM(catop.denumire) 
					when Tip_resursa='G' then RTRIM(gr.denumire) 
					when Tip_resursa='A' then rTrim(a.Nr_circulatie)+' - '+rTrim(a.Marca)+
						' '+rTrim(a.Model) 
					when 90=0 and Tip_resursa='R' then 'Factura '+rTrim (p.Cod_gestiune)+' din '+
						Left (p.explicatii,10)+', tert '+rTrim (substring (p.explicatii,11,13))
					else RTRIM(nomencl.Denumire) end) as denumire, 
		    CONVERT(decimal(17,3),p.Cantitate) as cantitate,
			CONVERT(decimal(17,2),p.Timp_normat) as timpnormat,
			CONVERT(decimal(17,5),p.Tarif_orar) as tarif,
			CONVERT(decimal(17,5),p.Pret_de_stoc) as pretdestoc,
			CONVERT(decimal(17,2),p.Adaos) as adaos, 
			CONVERT(decimal(17,0),p.Discount) as discount, 
			CONVERT(decimal(17,5),p.Pret_vanzare) as pretvanzare,
		    RTRIM(p.Cont_de_stoc) as contdestoc,
		    RTRIM(p.Cod_corespondent) as barcod,
			RTRIM (convert(varchar(20),p.Data_lansarii,101)) as dataplanificata,
			RTRIM(p.Ora_planificata) as oraplanificata,
		    RTRIM(p.Numar_consum) as nrconsum,
			RTRIM (convert(varchar(20),p.Data_finalizarii,101)) as datafinalizarii,
			RTRIM(p.Ora_finalizarii) as orafinalizarii,
		    RTRIM(p.Cod_gestiune) as gestiune,
		    RTRIM(g.Denumire_gestiune) as dengestiune,
			RTRIM(p.Stare_pozitie) as starepozitie, 
		    RTRIM(p.Loc_de_munca) as locmunca,
		    RTRIM(p.Marca) as marca,
		    RTRIM(personal.Nume) as numesalariat,
			RTRIM(p.Cod_intrare) as codintrare, 
			RTRIM(p.Utilizator_consum) as utilizatorconsum, 
			RTRIM(p.Utilizator_facturare) as utilizatorfacturare, 
			RTRIM(p.Numar_aviz) as nraviz, 
			RTRIM (convert(varchar(20),p.Data_facturarii,101)) as datafacturarii,
			RTRIM(p.Promotie) as promotie, 
			CONVERT(decimal(17,0),p.Generatie) as generatie, 
			convert(bit,p.Confirmat_telefonic) as confirmattelefonic, 
			RTRIM(substring(p.Explicatii,11,13)) as tertfactrefact, 
		    RTRIM(t.Denumire) as dentertfactrefact,
			(case when Tip_resursa = 'R' then convert(char(10),convert(datetime,SUBSTRING(p.Explicatii,4,3)
				+left(p.Explicatii,3)+SUBSTRING(p.Explicatii,7,4)),101) else '' end) as datafactrefact, 
			CONVERT(decimal(17,0),p.Cota_TVA) as cotaTVA, 
			--CONVERT(decimal(17,2),p.Cantitate*p.Pret_vanzare*((100.00-p.Discount)/100.00)) as valoare, 
			CONVERT(decimal(17,2),round(p.Cantitate*p.Pret_vanzare*((100.00-p.Discount)/100.00)*
				(100.00+p.Cota_TVA)/100.00,3)) as valoarecutva,
			--in functie de stare, se atribuie o anumita culoare inregistrarilor
			(case when p.Stare_pozitie = 0 then '#000000' 
				  when p.Stare_pozitie = 1 then '#0000FF' 
				  when p.Stare_pozitie = 2 then '#FF0000' 
										   else '#808080' end)  as culoare
				-- stare = 0 - Neacceptat; (Negru)
				-- stare = 1 - Lucru;      (Albastru)
				-- stare = 2 - Finalizat;  (Verde)
				-- stare = 3 - Facturat;   (Maro)
			FROM pozdevauto p
				Left join nomencl on nomencl.Cod=p.Cod 
				Left join auto a on a.Cod=p.Cod 	
				Left join terti t on p.Tip_resursa='R' and t.Tert=substring(p.Explicatii,11,13)
				Left join catop on catop.Cod=p.Cod 
				Left join grupe gr on gr.Grupa=p.Cod	
				Left join personal on personal.Marca=p.Marca 
				Left join gestiuni g on g.Cod_gestiune=p.Cod_gestiune	
			WHERE p.Cod_deviz =@nrdeviz and p.tip_resursa=pp.tip 
				and (case	when Tip_resursa='M' then RTRIM(catop.denumire) 
							when Tip_resursa='G' then RTRIM(gr.denumire) 
							when Tip_resursa='A' then rTrim(a.Nr_circulatie)+' - '+rTrim(a.Marca)+
								' '+rTrim(a.Model) 
							when Tip_resursa='R' then 'Refacturare - factura '+
								rTrim (p.Cod_gestiune)+' din '+Left (p.explicatii,10)+', tert '+
								rTrim (substring (p.explicatii,11,13))
							else RTRIM(nomencl.Denumire) end) like @cautare	
			ORDER BY p.Tip, p.Cod_deviz, p.Tip_resursa, p.Cod
		for xml raw,type)
	from (select distinct tip_resursa as tip from pozdevauto 
				where pozdevauto.Tip='D' and Cod_deviz=@nrdeviz /*and Tip_resursa in ('P','M')*/) pp 
				order by pp.Tip desc
	for xml raw,root('Ierarhie')
	)
	-- creare ierarhie pentru tipurile de resurse 
	declare @pretTotal float, @valoare float, @valoarecutva float, @pretvanzare float, 
		@tipresursa varchar(100), @tarif float
	set @pretvanzare=(case when @tipresursa='M' then @tarif 
							/*when @tipresursa='P' then */else @pretvanzare end) 
	if @doc is not null
	begin
								
			set @doc.modify('insert attribute coddeviz {sql:variable("@nrdeviz")}into (/Ierarhie/row)[1]')
			set @doc.modify('insert attribute coddeviz {sql:variable("@nrdeviz")}into (/Ierarhie)[1]')
			--Pret total piese
			/*set @pretTotal = (select SUM (convert(decimal(17,5),pret_vanzare)) 
				from pozdevauto where Cod_deviz like @nrdeviz	and tip_resursa='P')
			set @doc.modify('insert attribute pretvanzare {sql:variable("@pretTotal")}into (/Ierarhie/row[@denumire="Piese"])[1]')
			
			--Pret total manopera
			set @pretTotal = (select SUM(convert(decimal(17,5),pret_vanzare)) 
				from pozdevauto where Cod_deviz like @nrdeviz	and tip_resursa='M')
			set @doc.modify('insert attribute pretvanzare {sql:variable("@pretTotal")}into (/Ierarhie/row[@denumire="Manopera"])[1]')			
			*/
			--Valoare cu TVA piese 
			set @valoarecutva = (select sum(convert(decimal(17,2),round(Cantitate*Pret_vanzare*
				(1.00-Discount/100)*(1.00+Cota_TVA/100),3))) --((100.00-Discount)/100.00)*(100.00+Cota_TVA)/100.00
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='P')
			set @doc.modify('insert attribute valoarecutva{sql:variable("@valoarecutva")}into (/Ierarhie/row[@denumire="Piese"])[1]')
			
			--Valoare cu TVA manopera
			set @valoarecutva= (select sum(convert(decimal(17,2),round(Cantitate*Pret_vanzare*
				(1.00-Discount/100)*(1.00+Cota_TVA/100),3))) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='M')
			set @doc.modify('insert attribute valoarecutva {sql:variable("@valoarecutva")}into (/Ierarhie/row[@denumire="Manopera"])[1]')
			
			--Valoare cu TVA refacturari
			set @valoarecutva = (select sum(convert(decimal(17,2),round(Cantitate*Pret_vanzare*
				(1.00-Discount/100)*(1.00+Cota_TVA/100),3))) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='R')
			set @doc.modify('insert attribute valoarecutva{sql:variable("@valoarecutva")}into (/Ierarhie/row[@denumire="Refacturari"])[1]')
			
			--Valoare cu TVA servicii 
			set @valoarecutva= (select sum(convert(decimal(17,2),round(Cantitate*Pret_vanzare*
				(1.00-Discount/100)*(1.00+Cota_TVA/100),3))) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='S')
			set @doc.modify('insert attribute valoarecutva {sql:variable("@valoarecutva")}into (/Ierarhie/row[@denumire="Servicii prestate"])[1]')
			
			--Valoare cu TVA grupe de piese
			set @valoarecutva = (select sum(convert(decimal(17,2),round(Cantitate*Pret_vanzare*
				(1.00-Discount/100)*(1.00+Cota_TVA/100),3))) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='G')
			set @doc.modify('insert attribute valoarecutva{sql:variable("@valoarecutva")}into (/Ierarhie/row[@denumire="Grupe de piese"])[1]')
			
			--Valoare cu TVA autovehicule
			set @valoarecutva= (select sum(convert(decimal(17,2),round(Cantitate*Pret_vanzare*
				(1.00-Discount/100)*(1.00+Cota_TVA/100),3))) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='A')
			set @doc.modify('insert attribute valoarecutva {sql:variable("@valoarecutva")}into (/Ierarhie/row[@denumire="Autovehicule"])[1]')
			
			--total piese
			set @valoare = (select sum(convert(decimal(17,2),Cantitate*Pret_vanzare)) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='P')
			set @doc.modify('insert attribute valoare {sql:variable("@valoare")}into (/Ierarhie/row[@denumire="Piese"])[1]')
			
			--total manopera
			set @valoare = (select sum(convert(decimal(17,2),Cantitate*Pret_vanzare)) 
				from pozdevauto where Cod_deviz = @nrdeviz	and tip_resursa='M')
			set @doc.modify('insert attribute valoare {sql:variable("@valoare")}into (/Ierarhie/row[@denumire="Manopera"])[1]')
	end
    if @doc is not null 
		--pastrare ierarhie expandata -'da'
		set @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')
	select @doc for xml path('Date')
