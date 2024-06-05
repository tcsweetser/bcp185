# bcp185
Working on ETL and Analysis of RPKI ROA and ROUTEVIEWs data for BCP185 compliance.


Good documentation to puruse now:
* https://docs.thousandeyes.com/product-documentation/tests/bgp-tests/working-with-raw-bgp-data


Processing RPKI data with rpki-client:
* Simply get the current ROA data with: sudo rpki-client -c data/


Use the schema.sql to create your database and index for best speed on queries.
Hints on loading data are in the load.sql file.

More bread crumibs: pgsql_history.txt with everything I did (repeatedly) to get some insights from this data.

Go hear for the presentation on this data: https://2024.apricot.net/assets/files/APIC378/bcp1851708914211_1708995978.pdf

Look and listen to the presentation here: https://youtu.be/sKy0ifGADBI?list=PLSnVjSuzLJcwqW3uz1JBZE1wo13VcrHsh&t=3504

ToDo:
* How can I get this into Tableau or dataviz it?
* Only a snapshot, but getting access to time-series versions of this doing a graph over time of the progress to BCP185 compliance.

