declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="D" codMeniu="D_CL" tip="CL" subtip="CL" update="0" numar="" data="12/26/2013" gestiune="101" dengestiune="MARFURI SI PIESE DE SCHIMB" tert="" punct_livrare="" valabilitate="12/26/2013" lm="" gestiune_primitoare="" explicatii="" idContractCorespondent="" cantitate="0" pret="0" discount="0" termen="12/26/2013" cod="" searchText="cen"><detalii><row responsabil=""/></detalii></row>')
--exec wACNomenclator @sesiune='6BC5671FE9F46',@parXML=@p2
select @p2