--***
/**	functie care returneaza salariatii din istoric personal la care s-a modificat 
	procentul de spor specific fata de luna anterioara */
Create 
function [dbo].[fModifProcSporSpecific] (@DataJ datetime, @DataS datetime, @Marca char(6))
returns @ModifProcSpSpec table 
	(Data datetime, Marca char(6), Nume char(50), Cod_functie char(6), Loc_de_munca char(9), Spor_specific_ant float, Spor_specific float)
As
Begin
	declare @DataJNext datetime, @DataSNext datetime, @utilizator varchar(20)

	Set @DataJNext=dbo.bom(DateAdd(month,1,@DataS))
	Set @DataSNext=dbo.eom(DateAdd(month,1,@DataS))
	
	SET @utilizator = dbo.fIaUtilizator(null)

	insert @ModifProcSpSpec
	select a.Data, a.Marca, a.Nume, a.Cod_functie, a.Loc_de_munca, isnull(b.Spor_specific,0), a.Spor_specific
	from istPers a  
	left outer join istPers b on b.Data=dbo.eom(DateAdd(month,-1,a.Data)) and b.marca=a.marca
	left outer join net c on a.data=c.data and a.marca=c.marca 
	where a.data between @DataJ and @DataS and (@Marca='' or a.marca=@Marca) 
		and a.Spor_specific<>isnull(b.Spor_specific,0)
	Order by a.Marca
	return
End

/*
	select * from fModifProcSporSpecific('09/01/2011', '09/30/2011', '')
*/
