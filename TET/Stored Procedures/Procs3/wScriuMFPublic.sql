--***

CREATE procedure wScriuMFPublic @sesiune varchar(50), @parXML xml
as  

Declare @update bit, @cod varchar(20), @denumire varchar(2000), @o_cod varchar(20)

Set @update = isnull(@parXML.value('(/row/@update)[1]','bit'),0)
Set @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')
Set @denumire = @parXML.value('(/row/@denumire)[1]','varchar(2000)')
Set @o_cod= isnull(@parXML.value('(/row/@o_cod)[1]','varchar(20)'),'')

begin try
	/*if exists (select 1 from sys.objects where name='wScriuMFPublicSP' and type='P')  
	begin
		exec wScriuMFPublicSP @sesiune, @parXML
		return
	end*/ --sp_help MFPublice

	if @update=1 and isnull(@cod,'')<>@o_cod and exists (select 1 from mfix where Subunitate='DENS4' and serie=@o_cod)
	begin
		raiserror('Nu este permisa schimbarea codului, deoarece codul vechi este folosit in documente sau in alte cataloage!',11,1)
		return
	end
	
	if (@update=0 or @update=1 and isnull(@cod,'')<>@o_cod) and exists (select 1 from MFpublice where cod=@cod)
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
		update MFpublice set cod=@cod, Denumire=@denumire
			where Cod=@o_cod
	end  
	else   
	begin
		declare @cod_par varchar(20)    
		/*if (isnull(@cod,'')='')  	
			exec wMaxCod 'cod','nomencl',@cod_par output
		else */
			set @cod_par=@cod --select * from MFPublic
		insert into MFPublice (Cod, Denumire)
			values (@cod_par,@denumire)
	end
	
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
