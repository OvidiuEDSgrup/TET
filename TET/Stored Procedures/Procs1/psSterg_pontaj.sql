--***
/**	proc. sterg pontaj automat	*/
Create
procedure psSterg_pontaj
@DataJ datetime, @DataS datetime, @pMarca char(6), @pLocm char(9), @pTip_stat char(100)
As
Begin
	declare @Sal_pe_comenzi int
	Set @Sal_pe_comenzi=dbo.iauParL('PS','SALCOM')
--	sterg din realcom daca se lucreaza cu [X]Incadrare salariati pe comenzi
	If @Sal_pe_comenzi=1 
		delete from realcom from realcom a 	
		left outer join infopers i on a.marca=i.marca, pontaj b 
		where a.data between @DataJ and @DataS 
		and (@pMarca='' or a.marca=@pMarca) and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%') and a.marca=b.marca 
		and a.loc_de_munca=b.loc_de_munca and a.data=b.data and a.Numar_document='PS'+rtrim(convert(char(10),b.Numar_curent)) 		
		and (@pTip_stat='' or i.Religia=@pTip_stat)

--	sterg pontaj
	delete from pontaj from pontaj a
		left outer join infopers i on a.marca=i.marca
	where a.data between @DataJ and @DataS 
		and (@pMarca='' or a.marca=@pMarca) and (@pLocm='' or a.loc_de_munca like rtrim(@pLocm)+'%')  
		and (@pTip_stat='' or i.Religia=@pTip_stat)
End		
