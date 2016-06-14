USE [TET]
GO

/****** Object:  StoredProcedure [dbo].[wACCodProprietati]    Script Date: 02/08/2012 13:11:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--***
ALTER procedure [dbo].[wACCodProprietati]   @sesiune varchar(30), @parXML XML
as
declare @cod varchar(20)
select  @cod = @parXML.value('(/row/@cod)[1]','varchar(20)')

select distinct top 100
	   rtrim(LTRIM(cp.descriere)) as denumire,
	   rtrim(p.Cod_proprietate) as cod
	   from proprietati p
		inner join catproprietati cp on cp.Cod_proprietate=p.Cod_proprietate and p.Tip='NOMENCL' 
for xml raw



GO

