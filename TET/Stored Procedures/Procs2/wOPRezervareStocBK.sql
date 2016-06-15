--***
create procedure wOPRezervareStocBK @sesiune varchar(50), @parXML xml 
as     
set transaction isolation level read uncommitted
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPRezervareStocBKSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPRezervareStocBKSP @sesiune, @parXML output
	return @returnValue
end

declare @REZSTOCBK int,@mesaj varchar(500),@gestiune_rez varchar(20),@dengest_rez varchar(50),@tert varchar(13),@numar varchar(20),
		@sub varchar(9),@numar_doc varchar(13),@data_rez datetime,@gestiune_sursa varchar(9),@tip varchar(2),@utilizator varchar(20)
begin try	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT	
	
	exec luare_date_par 'GE', 'REZSTOCBK', @REZSTOCBK output, 0, @gestiune_rez output
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	
	select 
		@numar=ISNULL(@parXML.value('(/parametri/@numar)[1]', 'varchar(20)'), ''),
		@numar_doc=ISNULL(@parXML.value('(/parametri/@numar_doc)[1]', 'varchar(13)'), ''),
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),
		@data_rez=ISNULL(@parXML.value('(/parametri/@data_rez)[1]', 'datetime'), ''),
		@gestiune_sursa=ISNULL(@parXML.value('(/parametri/@gestiune_sursa)[1]', 'varchar(9)'), ''),
		@tert=ISNULL(@parXML.value('(/parametri/@tert)[1]', 'varchar(20)'), '')
	
	set @dengest_rez= (select MAX(Denumire_gestiune) from gestiuni where Cod_gestiune=@gestiune_rez)	

	if @REZSTOCBK=0 
	begin
		select 'Nu au fost facute configurarile necesare lucrului cu gestiune pentru rezervari!' as textMesaj, 
			'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje') 
	end
	
	if isnull(@numar_doc,'')=''
	begin
		set @numar_doc=isnull((select max(numar) as nr from pozdoc where subunitate=@sub and tip='TE'--and (:2=0 or data between ':3' and ':4') 
										and numar like 'REZ%' /*and RTrim(factura)=RTrim(@numar)*/), '')
		if @numar_doc='' 
			set @numar_doc='REZ00000'																
		declare @nr int
		set @nr=CONVERT(int,SUBSTRING(@numar_doc,4,8)+1)
		set @numar_doc= 'REZ'+replace(str(@nr,5,0),' ','0')
	end	
	
	declare @input XML 	
	set @input=(select top 1 rtrim(subunitate) as '@subunitate','TE' as '@tip',
		@numar_doc as '@numar', convert(char(10),@data_rez,101) as '@data',rtrim(@gestiune_sursa) as '@gestiune',
		rtrim(@gestiune_rez) as '@gestprim',rtrim(@numar) as '@factura',
			
			--parcurgere pozitii comanda grupate pe cod(doar cele care au cantitate valida pentru rezervare)
			(select rtrim(r.cod) as '@cod',
				convert(decimal(12,2),dbo.valoare_minima(sum(r.Cant_aprobata)- --cantitate aprobata
					sum(r.Cant_realizata)- --cantitatea care a fost realizata 
						isnull((select sum(cantitate) from pozdoc where subunitate=@sub and tip='TE'and numar like 'REZ%' 
							and RTrim(factura)=RTrim(@numar) and cod=r.Cod and Pret_cu_amanuntul=CONVERT(decimal(17,3),r.pret*(1+max(r.Cota_TVA)/100))),0),--cantitate deja rezervata
				ISNULL((select sum(stoc) from stocuri s where s.cod=r.cod and s.Cod_gestiune=@gestiune_sursa and s.Tip_gestiune<>'F'),0)- --stocul disponibil pe gestiune
					ISNULL((select SUM(cantitate) from pozcon s where s.Subunitate=@sub and s.tip=@tip and s.Contract=@numar and s.Numar_pozitie<max(r.Numar_pozitie) and s.Cod=r.Cod),0)+
					isnull((select sum(cantitate) from pozdoc where subunitate=@sub and tip='TE'and numar like 'REZ%' 
						and RTrim(factura)=RTrim(@numar) and cod=r.Cod),0),0))--cantitatea pe pe comanda care a fost deja pregatita pentru rezervare(scrisa in xml)
				as '@cantitate',
			CONVERT(decimal(17,3),r.pret*(1+max(r.Cota_TVA)/100)) as '@pamanunt', MAX(CONVERT(decimal(10,2),r.cota_tva)) '@tvaneexigibil'	
			
			from pozcon r		
			where r.Subunitate=@sub and r.tip=@tip and r.Contract=@numar 
				and ISNULL((select sum(stoc) from stocuri s where s.Subunitate=@sub and s.cod=r.cod and s.Cod_gestiune=@gestiune_sursa and s.Tip_gestiune<>'F'),0)>0.001
			group by r.Cod,r.Pret
			having convert(decimal(12,2),dbo.valoare_minima(sum(r.cantitate)- --cantitate din pozitie
				sum(r.Cant_realizata)- --cantitatea care a fost realizata 
				isnull((select sum(cantitate) from pozdoc where subunitate=@sub and tip='TE'and numar like 'REZ%' 
					and RTrim(factura)=RTrim(@numar) and cod=r.Cod and Pret_cu_amanuntul=CONVERT(decimal(17,3),r.pret*(1+max(r.Cota_TVA)/100))),0),--cantitate deja rezervata
				ISNULL((select sum(stoc) from stocuri s where s.cod=r.cod and s.Cod_gestiune=@gestiune_sursa and s.Tip_gestiune<>'F' and stoc>0.001),0)- --stocul disponibil pe gestiune
					ISNULL((select SUM(cantitate) from pozcon s where s.Subunitate=@sub and s.tip=@tip and s.Contract=@numar and s.Numar_pozitie<max(r.Numar_pozitie) and s.Cod=r.Cod),0)+
					isnull((select sum(cantitate) from pozdoc where subunitate=@sub and tip='TE'and numar like 'REZ%' 
						and RTrim(factura)=RTrim(@numar) and cod=r.Cod),0),0))>0.001
			order by MAX(r.Numar_pozitie)	
			for XML path,type)
			
		from pozcon p
		where p.Subunitate=@sub and p.tip=@tip and p.Contract=@numar
		for xml Path,type)
	 
	--select CONVERT(varchar(max),@input)
	exec wScriuPozdoc @sesiune,@input
	if @input.exist ('/row/row')=1
		select 'S-a generat transferul cu numarul '+ rtrim(@numar_doc)+'!!' as textMesaj for xml raw, root('Mesaje')	
	else
		select 'Verificati cantitatile, nu a fost facuta rezervarea! ' as textMesaj for xml raw, root('Mesaje')		

	
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+'(wOPRezervareStocBK)'
end catch

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
--select * from pozdoc where tip='TE' order by data desc
