/*
Momentan procedura se apeleaza numai din meniul de bonuri, de aceea fortam anularea folosind @idAntetBon!

*/

create procedure wOPAnulareBon @sesiune varchar(50), @parXML xml
as
declare @numarbon varchar(20),@data datetime, @factura varchar(20),@tert varchar(20),@tip varchar(2), @valoare float,@casamarcat varchar(10),
		@DetaliereBonuri int, @NuTEAC int, @NrDoc char(8),@NrTE char(8),@sub int, @gestbon varchar(20), @vanzator varchar(20), @utilizator varchar(30), 
		@inputAnulareAP xml, @inputAnulareAC xml, @inputAnulareTE xml, @eroare varchar(2000), @idAntetBon int, @eBon bit, @anulareIncasare int

set transaction isolation level read uncommitted

exec luare_date_par 'PO','DETBON',@DetaliereBonuri output,0,''
exec luare_date_par 'PO','NUTEAC',@NuTEAC output,0,''
exec luare_date_par 'GE','SUBPRO',0,0,@sub output
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

select	@tip=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@numarbon=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@factura=ISNULL(@parXML.value('(/*/@factura)[1]', 'varchar(20)'), ''),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), '01/01/1901'),
		@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(20)'), ''),
		@valoare=ISNULL(@parXML.value('(/*/@valoare)[1]', 'float'), ''),
		@casamarcat=ISNULL(@parXML.value('(/*/@casam)[1]', 'float'), ''),
		@gestbon=ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), ''),
		/* in mod normal doar @idantetbon ar trebui citit - toate restul se pot citi din tabela. */
		@idAntetBon=ISNULL(@parXML.value('(/*/@idantetbon)[1]', 'int'), 0),
		@vanzator=ISNULL(@parXML.value('(/*/@vanzator)[1]', 'varchar(20)'), ''),
		@anulareIncasare=ISNULL(@parXML.value('(/*/@anulareIncasare)[1]', 'int'), '')--parametru care cere anularea si a incasarilor de pe factura care se anuleaza
		
begin try
	if @idAntetBon=0
		raiserror('Identificatorul bonului(idAntetBon) nu a fost trimis! Actualizati procedurile PVria.',11,1)
	
	--if not exists (select * from antetBonuri where idAntetBon=@idAntetBon)
		--raiserror('Document inexistent',11,1)
		
	begin tran anulareBon
	if @tip='BY' -- factura
	begin
		set @inputAnulareAP=(select 'AP' as tip, @factura as numar,@factura as factura, @data as datafacturii, @data as data, @tert as tert,
			1 as faraMesaj, @anulareIncasare as anularePI for xml raw('parametri'))
		exec wOPAnulareDoc @sesiune=@sesiune, @parXML=@inputAnulareAP
	end
	else -- @tip='BC' -- bon
	begin
		select @NrDoc = bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(50)') from antetBonuri where idAntetBon=@idAntetBon
		
		if isnull(@factura,'')<>'' -- daca s-a emis factura din bon, nu se mai poate anula.
		begin
			set @eroare='Acest bon este atasat facturii '+rtrim(@factura)+'. Bonul nu poate fi anulat.'
			raiserror(@eroare,11,1)
		end
		
		if @DetaliereBonuri=1
		begin
			if @NrDoc is null 
				set @NrDoc=left(RTrim(CONVERT(varchar(4),@casamarcat))+right(replace(str(@numarbon),' ','0'),4), 8)	
			
			set @inputAnulareAC = (select 'AC' as tip, @nrdoc as numar, @data as datafacturii, @data as data, 1 as faraMesaj for xml raw('parametri'))
			exec wOPAnulareDoc @sesiune=@sesiune, @parXML=@inputAnulareAC
			
			if @NuTEAC=0
			begin
				set @NrTE=@NrDoc
  				set @inputAnulareTE = (select 'TE' as tip, @nrTE as numar, @data as datafacturii, @data as data, 1 as faraMesaj for xml raw ('parametri'))
				exec wOPAnulareDoc @sesiune=@sesiune, @parXML=@inputAnulareTE
			end
		end
		else --@DetaliereBonuri=0 
		begin
			-- daca bonurile sunt cumulate, diminuam AC-ul si TE-ul cu cantitatile bonului anulat
			if @NrDoc is null 
				set @NrDoc='B'+LTrim(str(day(@Data)))+'G'+rtrim(@GestBon)
			set @NrTE=left('TE'+left(replace(convert(char(10),@Data,103),'/',''),4)+rtrim(@GestBon),8)
			
			declare @pozitii_bon table(cod varchar(20), cantitate float, pret float, primary key(cod, pret))
			declare @cod varchar(20), @cantTotala float, @cantPozitie float, @cantCurenta float, @numarPozitieCurenta int, 
					@cantInitiala float, @tipDoc char(2), @NrDocTemp varchar(20)
			
			-- iau codurile si cantitatile de anulat
			insert into @pozitii_bon(cod, cantitate, pret)
			select bp.Cod_produs, sum(bp.Cantitate), bp.pret
			from bp
			where Numar_bon=@numarbon and data=@data and Casa_de_marcat=@casamarcat and Vinzator=@vanzator
			and tip='21'
			group by Cod_produs, pret
			
			-- parcurg toate codurile in o bucla si scad cantitati
			while exists(select * from @pozitii_bon)
			begin
				select @cod=null, @cantTotala=null, @tipDoc='AC', @NrDocTemp=@NrDoc
				select top 1 @cod=p.cod, @cantTotala=p.cantitate
				from @pozitii_bon p
				
				-- salvez cant initiala pt. ca sa stiu cat sa diminuez si la transferuri.
				set @cantInitiala=@cantTotala
				
				-- parcurg liniile din pozdoc pt. a gasi liniile pentru care sa diminuez cantitatea
				-- le parcurg in ordine LIFO dupa numar pozitiie - ultimele vandute sa fie primele diminuate
				-- o parcurgere pentru AC si inca una pentru TE aferente
				stergPozDoc:
				
				while @cantTotala>0 
				begin
					select @numarPozitieCurenta=null, @cantPozitie=null, @cantCurenta=null
					
					select top 1 @cantPozitie=cantitate, @numarPozitieCurenta=p.numar_pozitie
					from pozdoc p
					where p.Subunitate=@sub and p.Tip=@tipDoc and p.Numar=@NrDocTemp and p.Data=@data and p.cod=@cod and abs(p.cantitate)>0.001
					order by p.numar_pozitie desc
					
					if @cantPozitie>@cantTotala
					begin
						set @cantCurenta=@cantTotala
						update pozdoc
							set Cantitate=Cantitate-@cantCurenta, TVA_deductibil = round(TVA_deductibil*(Cantitate-@cantCurenta)/cantitate,2)
						where Subunitate=@sub and Tip=@tipDoc and Numar=@NrDocTemp and Data=@data and Numar_pozitie=@numarPozitieCurenta
					end
					else
					begin
						set @cantCurenta=@cantPozitie
						
						delete from pozdoc
						where Subunitate=@sub and Tip=@tipDoc and Numar=@NrDocTemp and Data=@data and Numar_pozitie=@numarPozitieCurenta
					end
					
					if abs(@cantCurenta)<0.001
					begin
						set @eroare='Eroare la anularea iesirilor pentru produsul '+rtrim(@cod)+'.'+CHAR(13)+
							'Bucla infinita la identificare pozitie pozdoc.'+CHAR(13)+
							'Anularea bonului a esuat.'
						raiserror(@eroare,11,1)
					end
					set @cantTotala=@cantTotala-@cantCurenta
				end
				
				if @NuTEAC=0 and @tipDoc='AC'
				begin
					set @cantTotala=@cantInitiala
					set @tipDoc='TE'
					goto stergPozDoc
				end
				delete from @pozitii_bon where cod=@cod
			end
			
		end
		
	end 
	
	/* mitz: stergem si din bt deoarece la repornirea PVria sa nu descarce ce deja a fost anulat*/
	delete from bt where Numar_bon=@numarbon and data=@data and Casa_de_marcat=@casamarcat and Vinzator=@vanzator
	delete from bp where Numar_bon=@numarbon and data=@data and Casa_de_marcat=@casamarcat and Vinzator=@vanzator
	delete from antetBonuri where Numar_bon=@numarbon and data_bon=@data and Casa_de_marcat=@casamarcat 
			and Vinzator=@vanzator --and Chitanta='0'

	select 'Bonul cu numarul '+rtrim(@numarbon) +' din data de '+ltrim(convert(varchar(20),@data,103))+' a fost anulat cu succes! '  as textMesaj for xml raw, root('Mesaje')
	commit tran anulareBon
	
	if exists (select 1 from sysobjects where name='wOPAnulareBonSP2')
		exec wOPAnulareBonSP2 @sesiune, @parXML
	
end try	  
begin catch
	if @@TRANCOUNT>0
		rollback tran anulareBon
	set @eroare=ERROR_MESSAGE()+' (wOPAnulareBon)'
	raiserror(@eroare, 16, 1) 
end catch
