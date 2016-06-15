--***

CREATE procedure wScriuCodClasif @sesiune varchar(50), @parXML xml
as  

Declare @update bit, @cod varchar(20), @denumire varchar(2000), @o_cod varchar(20), 
	@grup bit, @dur float,@durmin float,@durmax float

Set @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
Set @denumire = @parXML.value('(/row/@denumire)[1]','varchar(2000)')
Set @grup = isnull(@parXML.value('(/row/@grup)[1]','bit'),0)
Set @dur = isnull(@parXML.value('(/row/@dur)[1]','float'),0)
Set @durmin = isnull(@parXML.value('(/row/@durmin)[1]','float'),0)
Set @durmax = isnull(@parXML.value('(/row/@durmax)[1]','float'),0)
Set @o_cod= isnull(@parXML.value('(/row/@o_cod)[1]','varchar(20)'),'')

begin try
	/*if exists (select 1 from sys.objects where name='wScriuCodClasifSP' and type='P')  
	begin
		exec wScriuCodClasifSP @sesiune, @parXML
		return
	end*/ --sp_help codclasif

	if @update=1 and isnull(@cod,'')<>@o_cod and exists (select 1 from mfix where left(Subunitate,4)<>'DENS' and Cod_de_clasificare=@o_cod)
	begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
	end
	
	if (@update=0 or @update=1 and isnull(@cod,'')<>@o_cod) and exists (select 1 from Codclasif where Cod_de_clasificare=@cod)
	begin
		raiserror('Acest cod exista deja!',11,1)
		return
	end

	if isnull(@cod,'')='' 
	begin
		raiserror('Cod necompletat!',11,1)
		return
	end
	
	if isnull(@denumire,'')='' --and not exists (select 1 from um where um.UM=@um)
	begin
		raiserror('Denumire necompletata!',11,1)
		return
	end
	
	if @update=1  
	begin  
		update Codclasif set Cod_de_clasificare=@cod, Este_grup=@grup, Denumire=@denumire, 
			DUR=@dur, DUR_min=@durmin, DUR_max=@durmax
			where Cod_de_clasificare=@o_cod
	end  
	else   
	begin
		declare @cod_par varchar(20)    
		/*if (isnull(@cod,'')='')  	
			exec wMaxCod 'cod','nomencl',@cod_par output
		else */
			set @cod_par=@cod --select * from Codclasif
		insert into codclasif (Cod_de_clasificare, Denumire, Este_grup, DUR_min, DUR_max, DUR)
			values (@cod_par,@denumire,@grup,@durmin,@durmax,@dur)
	end
	
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch 
