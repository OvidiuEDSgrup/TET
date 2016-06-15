--***
/**	procedura pentru actualizare extinfop **/
Create procedure ActExtinfop 
	(@DataJos datetime, @DataSus datetime, @pMarca char(6), @pLocm char(9))
as
begin try
--	am pus conditia 1=0 la cele 2 update-uri intrucat ele stricau datele introduse manual in CTRL+D.
	Update Extinfop Set Val_inf=Cod_functie
	from istPers a
		left outer join infopers b on a.marca = b.marca
	where (@pMarca='' or a.marca=@pMarca) 
		and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%') and a.Data=@DataSus and Extinfop.Marca=a.Marca 
		and Extinfop.cod_inf='DATAMFCT' and Extinfop.Data_inf between @DataJos and @DataSus 
		and isnull(Val_inf,'')<>Cod_functie and isnull(Val_inf,'')<>'' and 1=0

	Update Extinfop Set Val_inf=Mod_angajare
	from istPers a
		left outer join infopers b on a.marca = b.marca
	where (@pMarca='' or a.marca=@pMarca) 
		and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%') and a.Data=@DataSus and Extinfop.Marca=a.Marca 
		and Extinfop.cod_inf='DATAMDCTR' and Extinfop.Data_inf between @DataJos and @DataSus 
		and isnull(Val_inf,'')<>Mod_angajare and isnull(Val_inf,'')<>'' and 1=0
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura ActExtinfop (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
