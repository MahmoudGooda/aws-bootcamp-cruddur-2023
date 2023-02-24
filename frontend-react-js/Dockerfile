FROM node:16.18 AS build

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install

FROM node:16.18
COPY --from=build /frontend-react-js /frontend-react-js
WORKDIR /frontend-react-js
ENV PORT=3000
EXPOSE ${PORT}
CMD ["npm", "start"]