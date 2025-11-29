import React from 'react';
import { createRoot } from 'react-dom/client';

document.body.innerHTML = '<div id="app"></div>';

const Hello = () => {
  return (
    <div className="relative isolate overflow-hidden bg-gray-900 h-screen flex items-center">
      <div className="px-6 py-24 sm:px-6 sm:py-32 lg:px-8 w-full">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="text-balance text-1xl font-semibold tracking-tight text-white sm:text-8xl">
            CircleQuest
          </h2>
          <p className="mx-auto mt-6 max-w-xl text-pretty text-lg/8 text-gray-300 font-bold">
            We're so glad you're here.
          </p>
          <p className="mx-auto mt-6 max-w-xl text-pretty text-lg/8 text-gray-300 italic">
            We use various code assignment. Please read the instructions on the README of the repo provided to get started.
          </p>
        </div>
      </div>
      <svg
        viewBox="0 0 1024 1024"
        aria-hidden="true"
        className="absolute left-1/2 top-1/2 -z-10 size-[128rem] -translate-x-1/2 [mask-image:radial-gradient(closest-side,white,transparent)]"
      >
        <circle r={512} cx={512} cy={512} fill="url(#8d958450-c69f-4251-94bc-4e091a323369)" fillOpacity="0.7" />
        <defs>
          <radialGradient id="8d958450-c69f-4251-94bc-4e091a323369">
            <stop stopColor="#7775D6" />
            <stop offset={1} stopColor="#E935C1" />
          </radialGradient>
        </defs>
      </svg>
    </div>
  )
}

const root = createRoot(document.getElementById('app'));
root.render(<Hello/>);
